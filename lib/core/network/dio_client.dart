import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../config/app_config.dart';
import '../error/exceptions.dart';

/// 앱 전체가 공유하는 HTTP 클라이언트.
///
/// **이 파일이 네트워크의 단일 진입점입니다.** feature 안에서 `Dio()` 를 새로 만들지
/// 마세요. 토큰 첨부/오류 변환/재발급이 전부 빠집니다.
class DioClient {
  /// [dio] 는 테스트에서 가짜 인스턴스를 주입하기 위한 것입니다.
  ///
  /// [onUnauthorized] 는 재발급까지 실패했을 때 호출됩니다. **로그인 화면으로 보내는
  /// 것은 이 클라이언트의 책임이 아닙니다** - 라우터를 몰라야 하는 계층이라
  /// 호출부(`injector.dart`)가 콜백으로 주입합니다.
  DioClient({
    Dio? dio,
    TokenProvider? tokenProvider,
    TokenRefresher? tokenRefresher,
    this.onUnauthorized,
  }) : _dio = dio ?? Dio(),
       // 이름 있는 매개변수는 밑줄로 시작할 수 없어 초기화 형식 매개변수를 쓸 수 없습니다.
       // ignore: prefer_initializing_formals
       _tokenProvider = tokenProvider,
       // ignore: prefer_initializing_formals
       _tokenRefresher = tokenRefresher {
    _dio.options = BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: AppConfig.connectTimeout,
      receiveTimeout: AppConfig.receiveTimeout,
      contentType: Headers.jsonContentType,
      responseType: ResponseType.json,
      // 4xx/5xx 도 예외로 던지지 않고 우리가 직접 처리합니다.
      validateStatus: (status) => status != null && status < 500,
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _tokenProvider?.call();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
      ),
    );

    if (AppConfig.enableNetworkLog) {
      _dio.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          logPrint: (line) => debugPrint(line.toString()),
        ),
      );
    }
  }

  final Dio _dio;
  final TokenProvider? _tokenProvider;
  final TokenRefresher? _tokenRefresher;

  /// 재발급까지 실패해 로그아웃해야 할 때 호출되는 훅.
  final void Function()? onUnauthorized;

  Dio get raw => _dio;

  Future<T> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    required T Function(Object? data) parse,
  }) => _request(
    path,
    () => _dio.get<dynamic>(path, queryParameters: queryParameters),
    parse,
  );

  /// 파일 응답을 그대로 받는다. CSV 내보내기 같은 다운로드가 쓴다.
  ///
  /// 실패 응답은 JSON 이므로 [_handleResponse] 가 바이트를 도로 풀어서
  /// 오류 메시지를 읽는다.
  Future<Uint8List> getBytes(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) => _request(
    path,
    () => _dio.get<List<int>>(
      path,
      queryParameters: queryParameters,
      options: Options(responseType: ResponseType.bytes),
    ),
    (data) => Uint8List.fromList((data as List).cast<int>()),
  );

  Future<T> post<T>(
    String path, {
    Object? body,
    required T Function(Object? data) parse,
  }) => _request(path, () => _dio.post<dynamic>(path, data: body), parse);

  Future<T> patch<T>(
    String path, {
    Object? body,
    required T Function(Object? data) parse,
  }) => _request(path, () => _dio.patch<dynamic>(path, data: body), parse);

  Future<T> put<T>(
    String path, {
    Object? body,
    required T Function(Object? data) parse,
  }) => _request(path, () => _dio.put<dynamic>(path, data: body), parse);

  Future<void> delete(String path) =>
      _request<void>(path, () => _dio.delete<dynamic>(path), (_) {});

  Future<T> _request<T>(
    String path,
    Future<Response<dynamic>> Function() send,
    T Function(Object? data) parse,
  ) async {
    try {
      Response<dynamic> response = await send();

      // 액세스 토큰이 30분 만에 만료돼 401 이 왔을 수 있습니다. 재발급이 되면 한 번만
      // 다시 시도합니다 - `/auth/*` 는 대상에서 뺍니다. 로그인 실패까지 "토큰 만료"로
      // 보고 재발급을 시도하면 무한 루프가 됩니다.
      if ((response.statusCode ?? 0) == 401 &&
          !path.startsWith('/auth') &&
          _tokenRefresher != null) {
        final bool refreshed = await _tokenRefresher();
        if (refreshed) response = await send();
      }

      return _handleResponse(path, response, parse);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  T _handleResponse<T>(
    String path,
    Response<dynamic> response,
    T Function(Object? data) parse,
  ) {
    final status = response.statusCode ?? 0;
    final body = response.data;
    final map = body is Map<String, dynamic> ? body : _decodeErrorBytes(body);

    if (status == 401) {
      // 로그인 자체가 401 이면 "로그인 실패"이지 "로그아웃되었다"가 아닙니다.
      if (!path.startsWith('/auth')) onUnauthorized?.call();
      throw UnauthorizedException(
        map?['message'] as String? ?? '로그인이 필요합니다.',
      );
    }
    if (status == 403) {
      // 401 과 달리 재로그인해도 달라지지 않습니다. 로그아웃시키지 않습니다.
      throw ForbiddenException(
        map?['message'] as String? ?? '이 작업을 할 권한이 없습니다.',
      );
    }
    if (status < 200 || status >= 300) {
      throw ServerException(
        message: map?['message'] as String? ?? '요청을 처리하지 못했습니다.',
        code: map?['code'] as String? ?? 'UNKNOWN',
        statusCode: status,
      );
    }
    return parse(body);
  }

  /// 바이트로 받은 요청의 실패 본문. 서버 오류는 JSON 이라 도로 풀어야 메시지가 보인다.
  Map<String, dynamic>? _decodeErrorBytes(Object? body) {
    if (body is! List<int>) return null;
    try {
      final decoded = jsonDecode(utf8.decode(body));
      return decoded is Map<String, dynamic> ? decoded : null;
    } on FormatException {
      return null;
    }
  }

  AppException _mapDioException(DioException e) => switch (e.type) {
    DioExceptionType.connectionTimeout ||
    DioExceptionType.sendTimeout ||
    DioExceptionType.receiveTimeout => const NetworkException(
      '서버 응답이 너무 느립니다. 잠시 후 다시 시도해 주세요.',
    ),
    DioExceptionType.connectionError ||
    DioExceptionType.unknown => NetworkException(
      kDebugMode
          ? '관리자 백엔드에 연결할 수 없습니다. (${AppConfig.apiBaseUrl})'
          : '네트워크에 연결할 수 없습니다.',
    ),
    DioExceptionType.badCertificate => const NetworkException(
      '보안 인증서에 문제가 있습니다.',
    ),
    DioExceptionType.cancel => const NetworkException('요청이 취소되었습니다.'),
    DioExceptionType.badResponse => ServerException(
      message: '서버 오류가 발생했습니다.',
      code: 'INTERNAL_ERROR',
      statusCode: e.response?.statusCode,
    ),
    // dio 가 새 타입을 추가해도 앱이 깨지지 않게 기본 케이스를 둡니다.
    _ => const NetworkException(),
  };
}

/// 저장된 액세스 토큰을 돌려주는 함수.
typedef TokenProvider = Future<String?> Function();

/// 액세스 토큰 재발급을 시도합니다. 성공하면 `true` - 새 토큰은 이 함수 안에서
/// 이미 저장까지 끝난 상태입니다.
///
/// 동시에 여러 요청이 401 을 받아도 실제 `/auth/refresh` 호출은 한 번만 나가야
/// 합니다(리프레시 토큰은 1회용 회전). 그 중복 방지는 구현체가 책임집니다.
typedef TokenRefresher = Future<bool> Function();

import '../../../../core/error/exceptions.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/page_result.dart';
import '../dtos/auth_dto.dart';

/// 인증 관련 HTTP 호출. 엔드포인트 문자열은 여기에만 둡니다.
class AuthRemoteDataSource {
  const AuthRemoteDataSource(this._client);

  final DioClient _client;

  Future<TokenDto> login(String email, String password) => _client.post(
    '/auth/login',
    body: {'email': email, 'password': password},
    parse: (data) => TokenDto.fromJson(_asMap(data)),
  );

  Future<TokenDto> refresh(String refreshToken) => _client.post(
    '/auth/refresh',
    body: {'refreshToken': refreshToken},
    parse: (data) => TokenDto.fromJson(_asMap(data)),
  );

  Future<void> logout(String? refreshToken) => _client.post<void>(
    '/auth/logout',
    body: refreshToken == null ? null : {'refreshToken': refreshToken},
    parse: (_) {},
  );

  Future<AdminSummaryDto> me() => _client.get(
    '/auth/me',
    parse: (data) => AdminSummaryDto.fromJson(_asMap(data)),
  );

  Future<void> changePassword(String currentPassword, String newPassword) =>
      _client.patch<void>(
        '/auth/password',
        body: {'currentPassword': currentPassword, 'newPassword': newPassword},
        parse: (_) {},
      );

  Future<PageResult<AdminSummaryDto>> getAdmins({
    required int page,
    required int size,
  }) => _client.get(
    '/accounts',
    queryParameters: {'page': page, 'size': size},
    parse: (data) => PageResult.fromJson(data, AdminSummaryDto.fromJson),
  );

  Future<AdminSummaryDto> createAdmin(Map<String, dynamic> body) =>
      _client.post(
        '/accounts',
        body: body,
        parse: (data) => AdminSummaryDto.fromJson(_asMap(data)),
      );

  Future<AdminSummaryDto> updateAdmin(
    String adminId,
    Map<String, dynamic> body,
  ) => _client.patch(
    '/accounts/$adminId',
    body: body,
    parse: (data) => AdminSummaryDto.fromJson(_asMap(data)),
  );

  Future<void> deleteAdmin(String adminId) => _client.delete('/accounts/$adminId');

  /// 응답이 예상한 모양이 아니면 여기서 걸러 냅니다. 그대로 캐스팅하면
  /// 화면 깊은 곳에서 타입 오류로 터져 원인을 찾기 어렵습니다.
  static Map<String, dynamic> _asMap(Object? data) {
    if (data is Map<String, dynamic>) return data;
    throw const ParseException();
  }
}

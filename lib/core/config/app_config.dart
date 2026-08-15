import 'package:flutter/foundation.dart';

/// 빌드 시점에 주입되는 설정값.
///
/// **API 주소를 코드에 하드코딩하지 마세요.**
///
/// ```bash
/// flutter run -d chrome --dart-define-from-file=env/local.json
/// ```
///
/// `.env` 파일 방식을 쓰지 않는 이유는 서비스 프론트엔드와 같습니다 — 파일이 없으면
/// 런타임에 죽는데, `--dart-define` 은 기본값이 있어 클론 직후에도 그냥 실행됩니다.
abstract final class AppConfig {
  static const String _rawBaseUrl = String.fromEnvironment('API_BASE_URL');

  /// 관리자 백엔드는 8081에 뜹니다. 서비스 백엔드(8080)와 함께 띄울 수 있게 나눠 둔 값입니다.
  static String get _defaultBaseUrl {
    final String host = Uri.base.host.isEmpty ? 'localhost' : Uri.base.host;
    final String apiHost = host == 'localhost' ? '127.0.0.1' : host;
    return 'http://$apiHost:8081/api/admin';
  }

  static String get apiBaseUrl =>
      _rawBaseUrl.isNotEmpty ? _rawBaseUrl : _defaultBaseUrl;

  static const Duration connectTimeout = Duration(seconds: 10);

  /// 관리자 화면은 목록 조회가 대부분이라 서비스 앱만큼 길게 잡을 이유가 없습니다.
  /// (서비스 앱은 LLM 호출 때문에 30초입니다)
  static const Duration receiveTimeout = Duration(seconds: 15);

  /// 네트워크 로그. 릴리스 빌드에서는 자동으로 꺼집니다.
  static bool get enableNetworkLog => kDebugMode;

  /// 목록 화면의 기본 페이지 크기. 1440px 화면에서 스크롤 없이 한 화면에 들어오는 수입니다.
  static const int defaultPageSize = 20;
}

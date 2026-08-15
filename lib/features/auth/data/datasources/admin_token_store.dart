import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// 관리자 토큰 저장소.
///
/// 웹에서는 `flutter_secure_storage` 가 브라우저 저장소를 씁니다. 브라우저에서 완전한
/// 비밀 보관은 불가능하므로, 짧은 액세스 토큰(30분)과 회전하는 리프레시 토큰으로
/// 노출 창을 좁히는 쪽에 기댑니다 — 이건 서버 쪽 설계와 짝을 이루는 결정입니다.
class AdminTokenStore {
  AdminTokenStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const String _accessTokenKey = 'admin_access_token';
  static const String _refreshTokenKey = 'admin_refresh_token';

  final FlutterSecureStorage _storage;

  /// 요청마다 읽는 값이라 메모리에 들고 있습니다. 웹 저장소 읽기는 비동기라
  /// 매 요청마다 왕복하면 목록 화면에서 체감될 만큼 쌓입니다.
  String? _cachedAccessToken;

  Future<String?> read() async {
    return _cachedAccessToken ??= await _storage.read(key: _accessTokenKey);
  }

  Future<String?> readRefreshToken() => _storage.read(key: _refreshTokenKey);

  Future<void> save({
    required String accessToken,
    required String refreshToken,
  }) async {
    _cachedAccessToken = accessToken;
    await _storage.write(key: _accessTokenKey, value: accessToken);
    await _storage.write(key: _refreshTokenKey, value: refreshToken);
  }

  Future<void> clear() async {
    _cachedAccessToken = null;
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
  }
}

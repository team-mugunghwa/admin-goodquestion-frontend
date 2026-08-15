import 'package:flutter/foundation.dart';

import '../../../../core/error/failure.dart';
import '../../domain/entities/admin_account.dart';
import '../../domain/usecases/auth_use_cases.dart';

/// 로그인 상태를 앱 전체가 공유합니다.
///
/// **화면 단위 ViewModel 이 아니라 전역입니다.** 좌측 메뉴가 권한에 따라 항목을
/// 감추고, 라우터가 로그인 여부로 이동을 막고, 상단 바가 이름을 보여줍니다.
/// 이 세 곳이 각자 상태를 들면 로그아웃 후에도 메뉴가 남아 있는 식으로 어긋납니다.
///
/// `app.dart` 의 `MultiProvider` 에 올라가는 유일한 ViewModel 입니다.
class AdminSession extends ChangeNotifier {
  AdminSession({
    required LoginUseCase login,
    required LogoutUseCase logout,
    required RestoreSessionUseCase restoreSession,
  }) : _login = login,
       _logout = logout,
       _restoreSession = restoreSession;

  final LoginUseCase _login;
  final LogoutUseCase _logout;
  final RestoreSessionUseCase _restoreSession;

  AdminAccount? _admin;
  bool _restoring = true;
  String? _errorMessage;
  bool _signingIn = false;

  AdminAccount? get admin => _admin;
  bool get isSignedIn => _admin != null;

  /// 저장된 토큰으로 세션을 되살리는 중.
  ///
  /// 라우터가 이 값을 봅니다. 복구가 끝나기 전에 판단하면, 새로고침할 때마다
  /// 로그인 화면이 한 번 스쳤다가 사라집니다.
  bool get isRestoring => _restoring;

  bool get isSigningIn => _signingIn;
  String? get errorMessage => _errorMessage;

  /// 앱 시작 시 한 번 부릅니다.
  Future<void> restore() async {
    try {
      _admin = await _restoreSession();
    } catch (_) {
      // 복구 실패는 로그인 화면으로 보내면 됩니다. 여기서 오류를 띄우면
      // 서버가 잠깐 죽어 있을 때 첫 화면이 오류로 뒤덮입니다.
      _admin = null;
    } finally {
      _restoring = false;
      notifyListeners();
    }
  }

  Future<bool> signIn({required String email, required String password}) async {
    _signingIn = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _admin = await _login(email: email, password: password);
      return true;
    } catch (e) {
      _errorMessage = e is Failure
          ? e.message
          : Failure.fromException(e).message;
      return false;
    } finally {
      _signingIn = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    await _logout();
    _admin = null;
    _errorMessage = null;
    notifyListeners();
  }

  /// 토큰이 만료돼 서버가 401 을 돌려준 경우. `injector.dart` 가 연결합니다.
  ///
  /// 여기서 서버를 다시 부르지 않습니다. 이미 재발급까지 실패한 상태이고,
  /// 이 시점에 호출을 더 하면 실패가 실패를 부릅니다.
  void onSessionExpired() {
    if (_admin == null) return;
    _admin = null;
    _errorMessage = '로그인이 만료되었습니다. 다시 로그인해 주세요.';
    notifyListeners();
  }
}

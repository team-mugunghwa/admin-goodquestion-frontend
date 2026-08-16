import '../../../../core/network/page_result.dart';
import '../entities/admin_account.dart';

/// 인증과 관리자 계정 관리.
///
/// 구현은 `data/repositories/auth_repository_impl.dart` 에 있습니다. 이 인터페이스는
/// Dio 도 DTO 도 모릅니다.
abstract class AuthRepository {
  /// 로그인하고 토큰을 저장합니다.
  Future<AdminAccount> login({required String email, required String password});

  /// 저장된 토큰을 지우고 서버 세션도 끊습니다.
  ///
  /// 서버 호출이 실패해도 로컬 토큰은 반드시 지웁니다 - 로그아웃이 실패해서
  /// 로그인 상태로 남는 것이 더 나쁩니다.
  Future<void> logout();

  /// 저장된 토큰으로 현재 관리자를 조회합니다. 토큰이 없거나 만료면 null.
  ///
  /// 새로고침했을 때 로그인 화면이 한 번 스쳤다 사라지는 것을 막으려고, 앱 시작 시
  /// 이걸 먼저 부릅니다.
  Future<AdminAccount?> restoreSession();

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  // ---- 관리자 계정 관리 (최고관리자 전용) ----

  Future<PageResult<AdminAccount>> getAdmins({int page = 0, int size = 20});

  Future<AdminAccount> createAdmin({
    required String email,
    required String password,
    required String name,
    required AdminRole role,
  });

  Future<AdminAccount> updateAdmin({
    required String adminId,
    String? name,
    AdminRole? role,
    AdminStatus? status,
  });

  Future<void> deleteAdmin(String adminId);
}

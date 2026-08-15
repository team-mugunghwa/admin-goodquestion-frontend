import '../../../../core/network/page_result.dart';
import '../entities/admin_account.dart';
import '../repositories/auth_repository.dart';

/// 인증 관련 UseCase 모음.
///
/// 파일 하나에 여러 UseCase 를 두는 것은 서비스 프론트엔드와 같은 방식입니다
/// (`auth_use_cases.dart`, `my_page_use_cases.dart`). 한 동작에 클래스 하나라는
/// 규칙은 지키되, 서너 줄짜리 클래스마다 파일을 만들면 찾는 비용이 더 큽니다.

class LoginUseCase {
  const LoginUseCase(this._repository);
  final AuthRepository _repository;

  Future<AdminAccount> call({
    required String email,
    required String password,
  }) => _repository.login(email: email, password: password);
}

class LogoutUseCase {
  const LogoutUseCase(this._repository);
  final AuthRepository _repository;

  Future<void> call() => _repository.logout();
}

/// 앱 시작 시 저장된 토큰으로 세션을 복구합니다. 없으면 null.
class RestoreSessionUseCase {
  const RestoreSessionUseCase(this._repository);
  final AuthRepository _repository;

  Future<AdminAccount?> call() => _repository.restoreSession();
}

class ChangePasswordUseCase {
  const ChangePasswordUseCase(this._repository);
  final AuthRepository _repository;

  Future<void> call({
    required String currentPassword,
    required String newPassword,
  }) => _repository.changePassword(
    currentPassword: currentPassword,
    newPassword: newPassword,
  );
}

class GetAdminsUseCase {
  const GetAdminsUseCase(this._repository);
  final AuthRepository _repository;

  Future<PageResult<AdminAccount>> call({int page = 0, int size = 20}) =>
      _repository.getAdmins(page: page, size: size);
}

class CreateAdminUseCase {
  const CreateAdminUseCase(this._repository);
  final AuthRepository _repository;

  Future<AdminAccount> call({
    required String email,
    required String password,
    required String name,
    required AdminRole role,
  }) => _repository.createAdmin(
    email: email,
    password: password,
    name: name,
    role: role,
  );
}

class UpdateAdminUseCase {
  const UpdateAdminUseCase(this._repository);
  final AuthRepository _repository;

  Future<AdminAccount> call({
    required String adminId,
    String? name,
    AdminRole? role,
    AdminStatus? status,
  }) => _repository.updateAdmin(
    adminId: adminId,
    name: name,
    role: role,
    status: status,
  );
}

class DeleteAdminUseCase {
  const DeleteAdminUseCase(this._repository);
  final AuthRepository _repository;

  Future<void> call(String adminId) => _repository.deleteAdmin(adminId);
}

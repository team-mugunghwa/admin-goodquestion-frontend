import '../../../../core/config/app_config.dart';
import '../../../../core/network/page_result.dart';
import '../../../../core/presentation/base_view_model.dart';
import '../../domain/entities/admin_account.dart';
import '../../domain/usecases/auth_use_cases.dart';

class AdminAccountViewModel extends BaseViewModel {
  AdminAccountViewModel({
    required GetAdminsUseCase getAdmins,
    required CreateAdminUseCase createAdmin,
    required UpdateAdminUseCase updateAdmin,
    required DeleteAdminUseCase deleteAdmin,
  }) : _getAdmins = getAdmins,
       _createAdmin = createAdmin,
       _updateAdmin = updateAdmin,
       _deleteAdmin = deleteAdmin;

  final GetAdminsUseCase _getAdmins;
  final CreateAdminUseCase _createAdmin;
  final UpdateAdminUseCase _updateAdmin;
  final DeleteAdminUseCase _deleteAdmin;

  PageResult<AdminAccount> _admins = const PageResult.empty();
  PageResult<AdminAccount> get admins => _admins;

  Future<void> load({int page = 0}) => guard(() async {
    _admins = await _getAdmins(page: page, size: AppConfig.defaultPageSize);
  });

  Future<bool> create({
    required String email,
    required String password,
    required String name,
    required AdminRole role,
  }) async {
    final ok = await runTask(
      () => _createAdmin(
        email: email,
        password: password,
        name: name,
        role: role,
      ),
    );
    if (ok) await load(page: _admins.page);
    return ok;
  }

  Future<bool> changeStatus(AdminAccount admin, AdminStatus status) async {
    final ok = await runTask(
      () => _updateAdmin(adminId: admin.id, status: status),
    );
    if (ok) await load(page: _admins.page);
    return ok;
  }

  Future<bool> changeRole(AdminAccount admin, AdminRole role) async {
    final ok = await runTask(() => _updateAdmin(adminId: admin.id, role: role));
    if (ok) await load(page: _admins.page);
    return ok;
  }

  Future<bool> delete(String adminId) async {
    final ok = await runTask(() => _deleteAdmin(adminId));
    if (ok) await load(page: _admins.page);
    return ok;
  }
}

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/network/page_result.dart';
import '../../domain/entities/admin_account.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/admin_token_store.dart';
import '../datasources/auth_remote_data_source.dart';

/// 예외를 [Failure] 로 번역하고 토큰 저장을 함께 처리합니다.
class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl(this._remote, this._tokenStore);

  final AuthRemoteDataSource _remote;
  final AdminTokenStore _tokenStore;

  @override
  Future<AdminAccount> login({
    required String email,
    required String password,
  }) async {
    try {
      final token = await _remote.login(email, password);
      await _tokenStore.save(
        accessToken: token.accessToken,
        refreshToken: token.refreshToken,
      );
      return token.admin.toEntity();
    } on AppException catch (e) {
      throw Failure.fromException(e);
    }
  }

  @override
  Future<void> logout() async {
    final refreshToken = await _tokenStore.readRefreshToken();
    try {
      await _remote.logout(refreshToken);
    } on AppException {
      // 서버 호출이 실패해도 넘어갑니다. 로그아웃이 실패해서 로그인 상태로 남는 것이
      // 서버에 토큰이 남는 것보다 나쁩니다 - 그 토큰은 어차피 만료됩니다.
    } finally {
      await _tokenStore.clear();
    }
  }

  @override
  Future<AdminAccount?> restoreSession() async {
    final accessToken = await _tokenStore.read();
    if (accessToken == null || accessToken.isEmpty) return null;
    try {
      final me = await _remote.me();
      return me.toEntity();
    } on UnauthorizedException {
      // 액세스 토큰이 만료됐고 재발급도 실패한 상태입니다(DioClient 가 이미 시도).
      await _tokenStore.clear();
      return null;
    } on AppException catch (e) {
      throw Failure.fromException(e);
    }
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await _remote.changePassword(currentPassword, newPassword);
      // 서버가 이 계정의 리프레시 토큰을 전부 끊습니다. 로컬에 남은 토큰도 지워야
      // 다음 401 에서 헛된 재발급을 시도하지 않습니다.
      await _tokenStore.clear();
    } on AppException catch (e) {
      throw Failure.fromException(e);
    }
  }

  @override
  Future<PageResult<AdminAccount>> getAdmins({int page = 0, int size = 20}) =>
      _guard(
        () async => (await _remote.getAdmins(
          page: page,
          size: size,
        )).map((dto) => dto.toEntity()),
      );

  @override
  Future<AdminAccount> createAdmin({
    required String email,
    required String password,
    required String name,
    required AdminRole role,
  }) => _guard(
    () async => (await _remote.createAdmin({
      'email': email,
      'password': password,
      'name': name,
      'role': role.code,
    })).toEntity(),
  );

  @override
  Future<AdminAccount> updateAdmin({
    required String adminId,
    String? name,
    AdminRole? role,
    AdminStatus? status,
  }) => _guard(
    () async => (await _remote.updateAdmin(adminId, {
      if (name != null) 'name': name,
      if (role != null) 'role': role.code,
      if (status != null) 'status': status.code,
    })).toEntity(),
  );

  @override
  Future<void> deleteAdmin(String adminId) =>
      _guard(() => _remote.deleteAdmin(adminId));

  /// data 예외를 domain 실패로 번역합니다. 이 변환이 빠지면 화면이 Dio 예외를
  /// 직접 보게 되고, 그 순간 클린 아키텍처의 의미가 사라집니다.
  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on AppException catch (e) {
      throw Failure.fromException(e);
    }
  }
}

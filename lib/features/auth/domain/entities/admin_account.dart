/// 관리자 권한.
///
/// 서버의 같은 이름 enum과 값이 일치해야 합니다. 모르는 값이 오면 [ADMIN] 으로
/// 떨어뜨립니다 — 서버가 권한을 늘렸을 때 화면이 죽는 대신 좁은 권한으로 동작하는
/// 쪽이 안전합니다.
enum AdminRole {
  admin('ADMIN', '관리자'),
  superAdmin('SUPER_ADMIN', '최고관리자');

  const AdminRole(this.code, this.label);

  final String code;
  final String label;

  static AdminRole fromCode(String? code) => AdminRole.values.firstWhere(
    (role) => role.code == code,
    orElse: () => AdminRole.admin,
  );

  bool get canManageAdmins => this == AdminRole.superAdmin;
}

enum AdminStatus {
  active('ACTIVE', '사용중'),
  suspended('SUSPENDED', '정지');

  const AdminStatus(this.code, this.label);

  final String code;
  final String label;

  static AdminStatus fromCode(String? code) => AdminStatus.values.firstWhere(
    (status) => status.code == code,
    orElse: () => AdminStatus.active,
  );
}

/// 로그인한 관리자.
class AdminAccount {
  const AdminAccount({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    required this.status,
    this.lastLoginAt,
    this.createdAt,
  });

  final String id;
  final String email;
  final String name;
  final AdminRole role;
  final AdminStatus status;
  final DateTime? lastLoginAt;
  final DateTime? createdAt;
}

import '../../domain/entities/admin_account.dart';

/// 서버 JSON 을 Entity 로 옮깁니다.
///
/// DTO 와 Entity 를 나누는 이유: 서버 필드명이 바뀌어도 `toEntity()` 한 곳만
/// 고치면 됩니다. 화면 코드는 건드리지 않습니다.
class AdminSummaryDto {
  const AdminSummaryDto({
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
  final String role;
  final String status;
  final String? lastLoginAt;
  final String? createdAt;

  factory AdminSummaryDto.fromJson(Map<String, dynamic> json) =>
      AdminSummaryDto(
        id: json['id'] as String,
        email: json['email'] as String? ?? '',
        name: json['name'] as String? ?? '',
        role: json['role'] as String? ?? '',
        status: json['status'] as String? ?? '',
        lastLoginAt: json['lastLoginAt'] as String?,
        createdAt: json['createdAt'] as String?,
      );

  AdminAccount toEntity() => AdminAccount(
    id: id,
    email: email,
    name: name,
    role: AdminRole.fromCode(role),
    status: AdminStatus.fromCode(status),
    lastLoginAt: DateTime.tryParse(lastLoginAt ?? '')?.toLocal(),
    createdAt: DateTime.tryParse(createdAt ?? '')?.toLocal(),
  );
}

/// 로그인/재발급 응답.
class TokenDto {
  const TokenDto({
    required this.accessToken,
    required this.refreshToken,
    required this.admin,
  });

  final String accessToken;
  final String refreshToken;
  final AdminSummaryDto admin;

  factory TokenDto.fromJson(Map<String, dynamic> json) => TokenDto(
    accessToken: json['accessToken'] as String,
    refreshToken: json['refreshToken'] as String,
    admin: AdminSummaryDto.fromJson(json['admin'] as Map<String, dynamic>),
  );
}

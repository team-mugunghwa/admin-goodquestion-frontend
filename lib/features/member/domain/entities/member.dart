import '../../../../core/widgets/app_status_chip.dart';

enum MemberStatus {
  active('ACTIVE', '정상', StatusTone.positive),
  suspended('SUSPENDED', '정지', StatusTone.negative);

  const MemberStatus(this.code, this.label, this.tone);

  final String code;
  final String label;
  final StatusTone tone;

  static MemberStatus fromCode(String? code) => MemberStatus.values.firstWhere(
    (status) => status.code == code,
    orElse: () => MemberStatus.active,
  );

  static Map<MemberStatus, String> get labels => {
    for (final status in MemberStatus.values) status: status.label,
  };
}

class MemberSummary {
  const MemberSummary({
    required this.id,
    required this.name,
    required this.provider,
    required this.status,
    required this.locked,
    required this.childCount,
    this.email,
    this.lastLoginAt,
    this.createdAt,
  });

  final String id;
  final String name;
  final String? email;

  /// LOCAL / KAKAO / GOOGLE
  final String provider;
  final MemberStatus status;

  /// 로그인 실패로 잠긴 상태. 정지와는 다른 사유입니다.
  final bool locked;
  final int childCount;

  /// 마지막 접속 시각. 접속 기록이 없으면 null입니다.
  final DateTime? lastLoginAt;
  final DateTime? createdAt;
}

class ChildProfile {
  const ChildProfile({
    required this.id,
    required this.name,
    required this.birthYear,
    this.createdAt,
  });

  final String id;
  final String name;
  final int birthYear;
  final DateTime? createdAt;
}

class LoginSession {
  const LoginSession({
    required this.id,
    required this.active,
    this.createdAt,
    this.expiresAt,
    this.revokedAt,
  });

  final String id;
  final bool active;
  final DateTime? createdAt;
  final DateTime? expiresAt;
  final DateTime? revokedAt;
}

class StorySessionSummary {
  const StorySessionSummary({
    required this.id,
    required this.childName,
    required this.storyTitle,
    required this.status,
    required this.safetyFlagged,
    this.startedAt,
    this.completedAt,
    this.lastActivityAt,
  });

  final String id;
  final String childName;
  final String storyTitle;

  /// IN_PROGRESS / POST_ACTIVITY / COMPLETED / STOPPED
  final String status;

  /// 아이 발화에서 위험 신호가 감지된 세션. 확인이 필요합니다.
  final bool safetyFlagged;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime? lastActivityAt;

  String get statusLabel => switch (status) {
    'IN_PROGRESS' => '진행 중',
    'POST_ACTIVITY' => '후속 활동',
    'COMPLETED' => '완료',
    'STOPPED' => '중단',
    _ => status,
  };

  StatusTone get statusTone => switch (status) {
    'COMPLETED' => StatusTone.positive,
    'IN_PROGRESS' || 'POST_ACTIVITY' => StatusTone.info,
    _ => StatusTone.neutral,
  };
}

class MemberDetail {
  const MemberDetail({
    required this.id,
    required this.name,
    required this.provider,
    required this.status,
    required this.locked,
    required this.children,
    required this.loginSessions,
    required this.inquiryCount,
    this.email,
    this.lockedUntil,
    this.suspendedReason,
    this.suspendedAt,
    this.lastLoginAt,
    this.lastLoginIp,
    this.createdAt,
  });

  final String id;
  final String name;
  final String? email;
  final String provider;
  final MemberStatus status;
  final bool locked;
  final DateTime? lockedUntil;
  final String? suspendedReason;
  final DateTime? suspendedAt;

  /// 마지막 접속 시각. 로그인과 토큰 재발급이 모두 갱신합니다.
  final DateTime? lastLoginAt;

  /// 마지막 로그인 위치. 재발급으로는 갱신되지 않아 [lastLoginAt]과 시점이 다를 수 있습니다.
  final String? lastLoginIp;
  final DateTime? createdAt;
  final List<ChildProfile> children;
  final List<LoginSession> loginSessions;
  final int inquiryCount;

  int get activeSessionCount =>
      loginSessions.where((session) => session.active).length;
}

import '../../../core/network/page_result.dart';

/// 관리자 조작 기록 한 줄.
class AuditLog {
  const AuditLog({
    required this.id,
    required this.adminEmail,
    required this.action,
    required this.targetType,
    this.summary,
    this.ip,
    this.createdAt,
  });

  final String id;
  final String adminEmail;
  final String action;
  final String targetType;
  final String? summary;
  final String? ip;
  final DateTime? createdAt;

  String get actionLabel => switch (action) {
    'LOGIN' => '로그인',
    'LOGIN_FAILED' => '로그인 실패',
    'CREATE' => '생성',
    'UPDATE' => '수정',
    'DELETE' => '삭제',
    'PUBLISH' => '노출 변경',
    'SUSPEND' => '정지',
    'RESTORE' => '정지 해제',
    'REVOKE_SESSION' => '세션 종료',
    'ANSWER' => '답변',
    'NOTIFY' => '알림 발송',
    _ => action,
  };

  String get targetLabel => switch (targetType) {
    'ADMIN_ACCOUNT' => '관리자 계정',
    'NOTICE' => '공지',
    'GUIDE' => '이용안내',
    'STORY' => '이야기',
    'SCENE' => '장면',
    'CHARACTER' => '캐릭터',
    'TOPIC' => '주제',
    'INQUIRY' => '문의',
    'PARENT' => '사용자',
    _ => targetType,
  };
}

abstract class AuditLogRepository {
  Future<PageResult<AuditLog>> getLogs({
    String? targetType,
    int page = 0,
    int size = 20,
  });
}

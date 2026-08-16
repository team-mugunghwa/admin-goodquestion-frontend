import 'dart:typed_data';

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

  /// 화면에 쓰는 조작 이름. 새 조작이 생겨 짝이 없으면 원문을 그대로 보여
  /// 준다 - 모르는 값이라고 숨기면 로그가 빠진 것처럼 보인다.
  String get actionLabel => actionLabels[action] ?? action;

  String get targetLabel => targetLabels[targetType] ?? targetType;

  /// 필터 드롭다운도 같은 목록을 쓴다. 표와 필터의 이름이 다르면 헷갈린다.
  static const Map<String, String> actionLabels = {
    'LOGIN': '로그인',
    'LOGIN_FAILED': '로그인 실패',
    'CREATE': '생성',
    'UPDATE': '수정',
    'DELETE': '삭제',
    'PUBLISH': '노출 변경',
    'SUSPEND': '정지',
    'RESTORE': '정지 해제',
    'REVOKE_SESSION': '세션 종료',
    'ANSWER': '답변',
    'NOTIFY': '알림 발송',
    'READ_DATA': '데이터 조회',
  };

  static const Map<String, String> targetLabels = {
    'ADMIN_ACCOUNT': '관리자 계정',
    'NOTICE': '공지',
    'GUIDE': '이용안내',
    'STORY': '이야기',
    'SCENE': '장면',
    'CHARACTER': '캐릭터',
    'TOPIC': '주제',
    'INQUIRY': '문의',
    'PARENT': '사용자',
    'DATABASE': '데이터베이스',
    'AUDIT_LOG': '감사 로그',
  };
}

/// 감사 로그 필터. 목록과 CSV 내보내기가 같은 조건을 쓴다.
class AuditLogFilter {
  const AuditLogFilter({
    this.targetType,
    this.action,
    this.adminEmail,
    this.from,
    this.to,
  });

  final String? targetType;
  final String? action;
  final String? adminEmail;
  final DateTime? from;
  final DateTime? to;

  AuditLogFilter copyWith({
    String? Function()? targetType,
    String? Function()? action,
    String? Function()? adminEmail,
    DateTime? Function()? from,
    DateTime? Function()? to,
  }) => AuditLogFilter(
    targetType: targetType == null ? this.targetType : targetType(),
    action: action == null ? this.action : action(),
    adminEmail: adminEmail == null ? this.adminEmail : adminEmail(),
    from: from == null ? this.from : from(),
    to: to == null ? this.to : to(),
  );
}

/// 내려받은 CSV 파일.
class AuditLogCsv {
  const AuditLogCsv({required this.fileName, required this.bytes});

  final String fileName;
  final Uint8List bytes;
}

abstract class AuditLogRepository {
  Future<PageResult<AuditLog>> getLogs({
    AuditLogFilter filter = const AuditLogFilter(),
    int page = 0,
    int size = 20,
  });

  /// 필터에 걸린 로그 전체를 CSV 로 받는다. 서버가 10,000건 상한을 지킨다.
  Future<AuditLogCsv> exportCsv(AuditLogFilter filter);
}

import '../../../../core/widgets/app_status_chip.dart';

enum InquiryStatus {
  pending('PENDING', '답변 대기', StatusTone.caution),
  answered('ANSWERED', '답변 완료', StatusTone.positive),
  closed('CLOSED', '종료', StatusTone.neutral);

  const InquiryStatus(this.code, this.label, this.tone);

  final String code;
  final String label;
  final StatusTone tone;

  static InquiryStatus fromCode(String? code) => InquiryStatus.values.firstWhere(
    (status) => status.code == code,
    orElse: () => InquiryStatus.pending,
  );

  static Map<InquiryStatus, String> get labels => {
    for (final status in InquiryStatus.values) status: status.label,
  };
}

enum InquiryCategory {
  account('ACCOUNT', '계정'),
  payment('PAYMENT', '결제'),
  content('CONTENT', '콘텐츠'),
  bug('BUG', '오류 신고'),
  suggestion('SUGGESTION', '제안'),
  etc('ETC', '기타');

  const InquiryCategory(this.code, this.label);

  final String code;
  final String label;

  static InquiryCategory fromCode(String? code) => InquiryCategory.values
      .firstWhere((c) => c.code == code, orElse: () => InquiryCategory.etc);

  static Map<InquiryCategory, String> get labels => {
    for (final category in InquiryCategory.values) category: category.label,
  };
}

class InquirySummary {
  const InquirySummary({
    required this.id,
    required this.parentId,
    required this.parentName,
    required this.category,
    required this.title,
    required this.status,
    required this.answered,
    this.parentEmail,
    this.answeredAt,
    this.createdAt,
    this.assigneeEmail,
  });

  final String id;
  final String parentId;
  final String parentName;
  final String? parentEmail;
  final InquiryCategory category;
  final String title;
  final InquiryStatus status;
  final bool answered;
  final DateTime? answeredAt;
  final DateTime? createdAt;

  /// 담당자. 없으면 null 입니다.
  final String? assigneeEmail;

  /// 답변을 기다린 시간. 답변 대기가 아니면 null 입니다.
  ///
  /// [now] 를 받는 이유는 시각을 여기서 만들면 테스트가 흔들리기 때문입니다.
  Duration? waitingSince(DateTime now) {
    if (status != InquiryStatus.pending || createdAt == null) return null;
    final elapsed = now.difference(createdAt!);
    return elapsed.isNegative ? Duration.zero : elapsed;
  }
}

class InquiryAnswer {
  const InquiryAnswer({
    required this.id,
    required this.adminName,
    required this.content,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String adminName;
  final String content;
  final DateTime? createdAt;
  final DateTime? updatedAt;
}

class InquiryDetail {
  const InquiryDetail({
    required this.id,
    required this.parentId,
    required this.parentName,
    required this.category,
    required this.title,
    required this.content,
    required this.status,
    this.parentEmail,
    this.answeredAt,
    this.createdAt,
    this.answer,
    this.assigneeEmail,
    this.notes = const [],
  });

  final String id;
  final String parentId;
  final String parentName;
  final String? parentEmail;
  final InquiryCategory category;
  final String title;
  final String content;
  final InquiryStatus status;
  final DateTime? answeredAt;
  final DateTime? createdAt;

  /// 아직 답변이 없으면 null.
  final InquiryAnswer? answer;

  /// 담당자. 없으면 null 입니다.
  final String? assigneeEmail;

  /// 내부 메모. 오래된 것부터라 처리 과정이 시간 순서로 읽힙니다.
  final List<InquiryNote> notes;

  bool get hasAnswer => answer != null;
  bool get isClosed => status == InquiryStatus.closed;
}

/// 문의 내부 메모. 사용자에게 보이지 않습니다.
class InquiryNote {
  const InquiryNote({
    required this.id,
    required this.authorEmail,
    required this.body,
    this.createdAt,
  });

  final String id;
  final String authorEmail;
  final String body;
  final DateTime? createdAt;
}

/// 자주 쓰는 답변 템플릿.
class ReplyTemplate {
  const ReplyTemplate({
    required this.id,
    required this.title,
    required this.body,
    this.updatedAt,
  });

  final String id;
  final String title;
  final String body;
  final DateTime? updatedAt;

  /// 문의에 맞춰 자리표시자를 채운 본문.
  ///
  /// 새 자리표시자를 더하면 템플릿 관리 화면의 안내문도 같이 고쳐야 합니다.
  String renderFor(InquiryDetail inquiry) => body
      .replaceAll('{보호자}', inquiry.parentName)
      .replaceAll('{문의제목}', inquiry.title);
}

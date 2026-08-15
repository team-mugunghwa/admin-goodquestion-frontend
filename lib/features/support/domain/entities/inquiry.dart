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

  bool get hasAnswer => answer != null;
  bool get isClosed => status == InquiryStatus.closed;
}

import '../../../../core/domain/content_status.dart';

enum NoticeCategory {
  general('GENERAL', '일반'),
  update('UPDATE', '업데이트'),
  event('EVENT', '이벤트'),
  maintenance('MAINTENANCE', '점검');

  const NoticeCategory(this.code, this.label);

  final String code;
  final String label;

  static NoticeCategory fromCode(String? code) => NoticeCategory.values
      .firstWhere((c) => c.code == code, orElse: () => NoticeCategory.general);

  static Map<NoticeCategory, String> get labels => {
    for (final category in NoticeCategory.values) category: category.label,
  };
}

/// 목록 한 줄. 본문이 없습니다 - 목록에서 쓰지 않고, 공지 본문은 깁니다.
class NoticeSummary {
  const NoticeSummary({
    required this.id,
    required this.title,
    required this.category,
    required this.pinned,
    required this.status,
    required this.viewCount,
    this.publishedAt,
    this.authorName,
    this.createdAt,
  });

  final String id;
  final String title;
  final NoticeCategory category;
  final bool pinned;
  final ContentStatus status;
  final int viewCount;
  final DateTime? publishedAt;
  final String? authorName;
  final DateTime? createdAt;
}

class NoticeDetail {
  const NoticeDetail({
    required this.id,
    required this.title,
    required this.content,
    required this.category,
    required this.pinned,
    required this.status,
    required this.viewCount,
    this.publishedAt,
    this.authorName,
    this.updatedAt,
  });

  final String id;
  final String title;
  final String content;
  final NoticeCategory category;
  final bool pinned;
  final ContentStatus status;
  final int viewCount;
  final DateTime? publishedAt;
  final String? authorName;
  final DateTime? updatedAt;
}

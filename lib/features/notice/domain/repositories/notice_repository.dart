import '../../../../core/domain/content_status.dart';
import '../../../../core/network/page_result.dart';
import '../entities/notice.dart';

abstract class NoticeRepository {
  Future<PageResult<NoticeSummary>> getNotices({
    ContentStatus? status,
    String? keyword,
    int page = 0,
    int size = 20,
  });

  Future<NoticeDetail> getNotice(String noticeId);

  Future<NoticeDetail> createNotice({
    required String title,
    required String content,
    required NoticeCategory category,
    required bool pinned,
    required ContentStatus status,
  });

  /// 보낸 항목만 바뀝니다. null 은 "건드리지 마라"는 뜻입니다.
  Future<NoticeDetail> updateNotice({
    required String noticeId,
    String? title,
    String? content,
    NoticeCategory? category,
    bool? pinned,
    ContentStatus? status,
  });

  Future<void> deleteNotice(String noticeId);
}

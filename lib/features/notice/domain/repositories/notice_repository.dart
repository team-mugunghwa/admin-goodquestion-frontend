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

  /// 이전 내용들. 최신이 위입니다.
  Future<List<NoticeRevision>> getRevisions(String noticeId);

  /// 그 시점 내용으로 되돌립니다. 공개 여부는 바뀌지 않습니다.
  Future<NoticeDetail> revert({
    required String noticeId,
    required String revisionId,
  });

  /// 예약 공개를 겁니다. 초안에만 걸 수 있고 다시 걸면 시각이 바뀝니다.
  Future<NoticeDetail> schedule({
    required String noticeId,
    required DateTime publishAt,
  });

  Future<NoticeDetail> cancelSchedule(String noticeId);
}

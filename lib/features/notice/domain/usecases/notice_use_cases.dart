import '../../../../core/domain/content_status.dart';
import '../../../../core/network/page_result.dart';
import '../entities/notice.dart';
import '../repositories/notice_repository.dart';

/// 공지 UseCase 모음.

class GetNoticesUseCase {
  const GetNoticesUseCase(this._repository);
  final NoticeRepository _repository;

  Future<PageResult<NoticeSummary>> call({
    ContentStatus? status,
    String? keyword,
    int page = 0,
    int size = 20,
  }) => _repository.getNotices(
    status: status,
    keyword: keyword,
    page: page,
    size: size,
  );
}

class GetNoticeUseCase {
  const GetNoticeUseCase(this._repository);
  final NoticeRepository _repository;

  Future<NoticeDetail> call(String noticeId) => _repository.getNotice(noticeId);
}

class CreateNoticeUseCase {
  const CreateNoticeUseCase(this._repository);
  final NoticeRepository _repository;

  Future<NoticeDetail> call({
    required String title,
    required String content,
    required NoticeCategory category,
    required bool pinned,
    required ContentStatus status,
  }) => _repository.createNotice(
    title: title,
    content: content,
    category: category,
    pinned: pinned,
    status: status,
  );
}

class UpdateNoticeUseCase {
  const UpdateNoticeUseCase(this._repository);
  final NoticeRepository _repository;

  Future<NoticeDetail> call({
    required String noticeId,
    String? title,
    String? content,
    NoticeCategory? category,
    bool? pinned,
    ContentStatus? status,
  }) => _repository.updateNotice(
    noticeId: noticeId,
    title: title,
    content: content,
    category: category,
    pinned: pinned,
    status: status,
  );
}

class DeleteNoticeUseCase {
  const DeleteNoticeUseCase(this._repository);
  final NoticeRepository _repository;

  Future<void> call(String noticeId) => _repository.deleteNotice(noticeId);
}

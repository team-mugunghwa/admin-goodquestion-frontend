import '../../../../core/domain/content_status.dart';
import '../../../../core/presentation/base_view_model.dart';
import '../../domain/entities/notice.dart';
import '../../domain/usecases/notice_use_cases.dart';

/// 공지 작성·수정 화면의 상태.
///
/// 새 글([noticeId] 가 null)과 수정을 한 ViewModel 로 다룹니다. 화면이 거의 같고,
/// 나누면 폼 검증과 저장 흐름을 두 벌 유지하게 됩니다.
class NoticeEditViewModel extends BaseViewModel {
  NoticeEditViewModel({
    required GetNoticeUseCase getNotice,
    required CreateNoticeUseCase createNotice,
    required UpdateNoticeUseCase updateNotice,
    this.noticeId,
  }) : _getNotice = getNotice,
       _createNotice = createNotice,
       _updateNotice = updateNotice;

  final GetNoticeUseCase _getNotice;
  final CreateNoticeUseCase _createNotice;
  final UpdateNoticeUseCase _updateNotice;

  /// null 이면 새 글입니다.
  final String? noticeId;

  NoticeDetail? _notice;
  NoticeCategory _category = NoticeCategory.general;
  ContentStatus _status = ContentStatus.draft;
  bool _pinned = false;

  NoticeDetail? get notice => _notice;
  NoticeCategory get category => _category;
  ContentStatus get status => _status;
  bool get pinned => _pinned;
  bool get isNew => noticeId == null;

  Future<void> load() => guard(() async {
    if (noticeId == null) return;
    final notice = await _getNotice(noticeId!);
    _notice = notice;
    _category = notice.category;
    _status = notice.status;
    _pinned = notice.pinned;
  });

  void changeCategory(NoticeCategory category) {
    _category = category;
    safeNotify();
  }

  void changeStatus(ContentStatus status) {
    _status = status;
    safeNotify();
  }

  void togglePinned(bool pinned) {
    _pinned = pinned;
    safeNotify();
  }

  /// @return 저장된 공지. 실패하면 null 이고 [errorMessage] 에 이유가 담깁니다.
  Future<NoticeDetail?> save({
    required String title,
    required String content,
  }) async {
    NoticeDetail? saved;
    final ok = await runTask(() async {
      saved = noticeId == null
          ? await _createNotice(
              title: title,
              content: content,
              category: _category,
              pinned: _pinned,
              status: _status,
            )
          : await _updateNotice(
              noticeId: noticeId!,
              title: title,
              content: content,
              category: _category,
              pinned: _pinned,
              status: _status,
            );
      _notice = saved;
    });
    return ok ? saved : null;
  }
}

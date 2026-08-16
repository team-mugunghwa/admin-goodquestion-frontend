import '../../../../core/domain/content_status.dart';
import '../../../../core/presentation/base_view_model.dart';
import '../../domain/entities/notice.dart';
import '../../domain/usecases/notice_use_cases.dart';

/// 공지 작성/수정 화면의 상태.
///
/// 새 글([noticeId] 가 null)과 수정을 한 ViewModel 로 다룹니다. 화면이 거의 같고,
/// 나누면 폼 검증과 저장 흐름을 두 벌 유지하게 됩니다.
class NoticeEditViewModel extends BaseViewModel {
  NoticeEditViewModel({
    required GetNoticeUseCase getNotice,
    required CreateNoticeUseCase createNotice,
    required UpdateNoticeUseCase updateNotice,
    required GetNoticeRevisionsUseCase getRevisions,
    required RevertNoticeUseCase revertNotice,
    required ScheduleNoticeUseCase scheduleNotice,
    required CancelNoticeScheduleUseCase cancelSchedule,
    this.noticeId,
  }) : _getNotice = getNotice,
       _createNotice = createNotice,
       _updateNotice = updateNotice,
       _getRevisions = getRevisions,
       _revertNotice = revertNotice,
       _scheduleNotice = scheduleNotice,
       _cancelSchedule = cancelSchedule;

  final GetNoticeUseCase _getNotice;
  final CreateNoticeUseCase _createNotice;
  final UpdateNoticeUseCase _updateNotice;
  final GetNoticeRevisionsUseCase _getRevisions;
  final RevertNoticeUseCase _revertNotice;
  final ScheduleNoticeUseCase _scheduleNotice;
  final CancelNoticeScheduleUseCase _cancelSchedule;

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

  /// 이전 내용들. 이력 대화상자가 부를 때만 서버에 다녀옵니다.
  Future<List<NoticeRevision>> loadRevisions() async {
    if (noticeId == null) return const [];
    return _getRevisions(noticeId!);
  }

  /// 그 시점 내용으로 되돌립니다. 성공하면 화면 상태도 그 내용으로 바뀝니다.
  Future<NoticeDetail?> revert(String revisionId) async {
    if (noticeId == null) return null;
    NoticeDetail? reverted;
    final ok = await runTask(() async {
      reverted = await _revertNotice(
        noticeId: noticeId!,
        revisionId: revisionId,
      );
    });
    if (ok && reverted != null) {
      _applyDetail(reverted!);
    }
    return ok ? reverted : null;
  }

  Future<bool> schedule(DateTime publishAt) async {
    if (noticeId == null) return false;
    final ok = await runTask(() async {
      _applyDetail(
        await _scheduleNotice(noticeId: noticeId!, publishAt: publishAt),
      );
    });
    return ok;
  }

  Future<bool> cancelSchedule() async {
    if (noticeId == null) return false;
    final ok = await runTask(() async {
      _applyDetail(await _cancelSchedule(noticeId!));
    });
    return ok;
  }

  void _applyDetail(NoticeDetail detail) {
    _notice = detail;
    _category = detail.category;
    _status = detail.status;
    _pinned = detail.pinned;
    safeNotify();
  }
}

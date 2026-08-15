import '../../../../core/config/app_config.dart';
import '../../../../core/domain/content_status.dart';
import '../../../../core/network/page_result.dart';
import '../../../../core/presentation/base_view_model.dart';
import '../../domain/entities/notice.dart';
import '../../domain/usecases/notice_use_cases.dart';

class NoticeListViewModel extends BaseViewModel {
  NoticeListViewModel({
    required GetNoticesUseCase getNotices,
    required DeleteNoticeUseCase deleteNotice,
  }) : _getNotices = getNotices,
       _deleteNotice = deleteNotice;

  final GetNoticesUseCase _getNotices;
  final DeleteNoticeUseCase _deleteNotice;

  PageResult<NoticeSummary> _notices = const PageResult.empty();
  ContentStatus? _status;
  String _keyword = '';

  PageResult<NoticeSummary> get notices => _notices;
  ContentStatus? get status => _status;
  String get keyword => _keyword;

  Future<void> load({int page = 0}) => guard(() async {
    _notices = await _getNotices(
      status: _status,
      keyword: _keyword,
      page: page,
      size: AppConfig.defaultPageSize,
    );
  });

  /// 필터를 바꾸면 첫 페이지로 돌아갑니다. 3페이지를 보다가 상태를 바꾸면
  /// 결과가 한 페이지뿐일 수 있는데, 그때 3페이지에 머물면 빈 화면이 뜹니다.
  Future<void> changeStatus(ContentStatus? status) {
    _status = status;
    return load();
  }

  Future<void> search(String keyword) {
    _keyword = keyword.trim();
    return load();
  }

  Future<bool> delete(String noticeId) async {
    final ok = await runTask(() => _deleteNotice(noticeId));
    if (ok) {
      // 지운 뒤 보던 페이지를 그대로 다시 부릅니다. 첫 페이지로 되돌리면
      // 여러 건을 정리하는 중에 매번 위로 튕깁니다.
      await load(page: _notices.page);
    }
    return ok;
  }
}

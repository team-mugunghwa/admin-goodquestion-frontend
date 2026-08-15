import 'package:flutter_test/flutter_test.dart';
import 'package:goodquestion_admin/core/domain/content_status.dart';
import 'package:goodquestion_admin/core/error/failure.dart';
import 'package:goodquestion_admin/core/network/page_result.dart';
import 'package:goodquestion_admin/core/state/view_state.dart';
import 'package:goodquestion_admin/features/notice/domain/entities/notice.dart';
import 'package:goodquestion_admin/features/notice/domain/repositories/notice_repository.dart';
import 'package:goodquestion_admin/features/notice/domain/usecases/notice_use_cases.dart';
import 'package:goodquestion_admin/features/notice/presentation/viewmodels/notice_list_view_model.dart';
import 'package:mocktail/mocktail.dart';

class _MockNoticeRepository extends Mock implements NoticeRepository {}

NoticeSummary _notice(String id) => NoticeSummary(
  id: id,
  title: '공지 $id',
  category: NoticeCategory.general,
  pinned: false,
  status: ContentStatus.published,
  viewCount: 0,
);

void main() {
  late _MockNoticeRepository repository;
  late NoticeListViewModel viewModel;

  setUp(() {
    repository = _MockNoticeRepository();
    viewModel = NoticeListViewModel(
      getNotices: GetNoticesUseCase(repository),
      deleteNotice: DeleteNoticeUseCase(repository),
    );
  });

  PageResult<NoticeSummary> pageOf(List<NoticeSummary> notices, {int page = 0}) =>
      PageResult(
        content: notices,
        page: page,
        size: 20,
        totalElements: notices.length,
        totalPages: 1,
      );

  test('불러오면 성공 상태가 되고 목록이 채워진다', () async {
    when(
      () => repository.getNotices(
        status: any(named: 'status'),
        keyword: any(named: 'keyword'),
        page: any(named: 'page'),
        size: any(named: 'size'),
      ),
    ).thenAnswer((_) async => pageOf([_notice('1'), _notice('2')]));

    await viewModel.load();

    expect(viewModel.state, ViewState.success);
    expect(viewModel.notices.content, hasLength(2));
  });

  test('필터를 바꾸면 첫 페이지부터 다시 불러온다', () async {
    when(
      () => repository.getNotices(
        status: any(named: 'status'),
        keyword: any(named: 'keyword'),
        page: any(named: 'page'),
        size: any(named: 'size'),
      ),
    ).thenAnswer((_) async => pageOf([_notice('1')], page: 3));

    // 3페이지를 보다가 상태를 바꾸면 결과가 한 페이지뿐일 수 있는데,
    // 그때 3페이지에 머물면 빈 화면이 뜹니다.
    await viewModel.load(page: 3);
    await viewModel.changeStatus(ContentStatus.draft);

    // 바뀐 상태로 0페이지를 다시 부르는 호출이 정확히 한 번 나가야 한다.
    verify(
      () => repository.getNotices(
        status: ContentStatus.draft,
        keyword: '',
        page: 0,
        size: 20,
      ),
    ).called(1);
  });

  test('삭제에 실패하면 오류 메시지가 남고 목록은 그대로다', () async {
    when(
      () => repository.getNotices(
        status: any(named: 'status'),
        keyword: any(named: 'keyword'),
        page: any(named: 'page'),
        size: any(named: 'size'),
      ),
    ).thenAnswer((_) async => pageOf([_notice('1')]));
    when(() => repository.deleteNotice(any())).thenThrow(
      const ServerFailure(message: '삭제하지 못했습니다.', code: 'INTERNAL_ERROR'),
    );

    await viewModel.load();
    final ok = await viewModel.delete('1');

    expect(ok, isFalse);
    expect(viewModel.errorMessage, '삭제하지 못했습니다.');
    // 조회 화면이 스피너로 덮이지 않아야 합니다. 목록은 그대로 남습니다.
    expect(viewModel.state, ViewState.success);
    expect(viewModel.notices.content, hasLength(1));
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:goodquestion_admin/core/domain/content_status.dart';
import 'package:goodquestion_admin/core/error/failure.dart';
import 'package:goodquestion_admin/features/notice/domain/entities/notice.dart';
import 'package:goodquestion_admin/features/notice/domain/repositories/notice_repository.dart';
import 'package:goodquestion_admin/features/notice/domain/usecases/notice_use_cases.dart';
import 'package:goodquestion_admin/features/notice/presentation/viewmodels/notice_edit_view_model.dart';
import 'package:mocktail/mocktail.dart';

class _MockNoticeRepository extends Mock implements NoticeRepository {}

NoticeDetail _detail({
  String title = '점검 안내',
  String content = '본문',
  ContentStatus status = ContentStatus.draft,
  DateTime? scheduledAt,
}) => NoticeDetail(
  id: 'n-1',
  title: title,
  content: content,
  category: NoticeCategory.general,
  pinned: false,
  status: status,
  viewCount: 0,
  scheduledPublishAt: scheduledAt,
);

void main() {
  late _MockNoticeRepository repository;

  NoticeEditViewModel buildViewModel({String? noticeId = 'n-1'}) =>
      NoticeEditViewModel(
        getNotice: GetNoticeUseCase(repository),
        createNotice: CreateNoticeUseCase(repository),
        updateNotice: UpdateNoticeUseCase(repository),
        getRevisions: GetNoticeRevisionsUseCase(repository),
        revertNotice: RevertNoticeUseCase(repository),
        scheduleNotice: ScheduleNoticeUseCase(repository),
        cancelSchedule: CancelNoticeScheduleUseCase(repository),
        noticeId: noticeId,
      );

  setUp(() {
    repository = _MockNoticeRepository();
  });

  test('예약을 걸면 화면 상태에 예약 시각이 실린다', () async {
    final at = DateTime(2026, 8, 20, 10, 0);
    when(
      () => repository.schedule(
        noticeId: 'n-1',
        publishAt: at,
      ),
    ).thenAnswer((_) async => _detail(scheduledAt: at));

    final viewModel = buildViewModel();
    final ok = await viewModel.schedule(at);

    expect(ok, isTrue);
    expect(viewModel.notice?.scheduledPublishAt, at);
    expect(viewModel.notice?.isScheduled, isTrue);
  });

  test('새 글에는 예약을 걸 수 없다', () async {
    // 저장 전에는 서버에 공지가 없어 예약을 붙일 대상이 없다.
    final viewModel = buildViewModel(noticeId: null);
    final ok = await viewModel.schedule(DateTime(2026, 8, 20));

    expect(ok, isFalse);
    verifyNever(
      () => repository.schedule(
        noticeId: any(named: 'noticeId'),
        publishAt: any(named: 'publishAt'),
      ),
    );
  });

  test('되돌리면 화면 상태가 그 시점 내용으로 바뀐다', () async {
    when(
      () => repository.revert(noticeId: 'n-1', revisionId: 'r-1'),
    ).thenAnswer(
      (_) async => _detail(title: '점검 안내 (원본)', content: '원본 본문'),
    );

    final viewModel = buildViewModel();
    final reverted = await viewModel.revert('r-1');

    expect(reverted?.title, '점검 안내 (원본)');
    expect(viewModel.notice?.title, '점검 안내 (원본)');
    expect(viewModel.notice?.content, '원본 본문');
  });

  test('예약이 거절되면 서버가 준 이유가 남는다', () async {
    when(
      () => repository.schedule(
        noticeId: any(named: 'noticeId'),
        publishAt: any(named: 'publishAt'),
      ),
    ).thenThrow(
      const ServerFailure(
        message: '초안 상태의 공지만 예약할 수 있습니다.',
        code: 'INVALID_REQUEST',
      ),
    );

    final viewModel = buildViewModel();
    final ok = await viewModel.schedule(DateTime(2026, 8, 20));

    expect(ok, isFalse);
    expect(viewModel.errorMessage, contains('초안'));
  });

  test('예약을 취소하면 예약 시각이 비워진다', () async {
    when(() => repository.cancelSchedule('n-1'))
        .thenAnswer((_) async => _detail());

    final viewModel = buildViewModel();
    final ok = await viewModel.cancelSchedule();

    expect(ok, isTrue);
    expect(viewModel.notice?.isScheduled, isFalse);
  });
}

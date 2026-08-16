import 'package:flutter_test/flutter_test.dart';
import 'package:goodquestion_admin/core/state/view_state.dart';
import 'package:goodquestion_admin/features/support/domain/entities/inquiry.dart';
import 'package:goodquestion_admin/features/support/domain/repositories/support_repository.dart';
import 'package:goodquestion_admin/features/support/domain/usecases/support_use_cases.dart';
import 'package:goodquestion_admin/features/support/presentation/viewmodels/inquiry_detail_view_model.dart';
import 'package:mocktail/mocktail.dart';

class _MockSupportRepository extends Mock implements SupportRepository {}

InquiryDetail _detail({String? assignee, List<InquiryNote> notes = const []}) =>
    InquiryDetail(
      id: 'inq-1',
      parentId: 'p-1',
      parentName: '김보호자',
      category: InquiryCategory.payment,
      title: '별가루가 안 들어와요',
      content: '어제 산 아이템이 안 보여요.',
      status: InquiryStatus.pending,
      assigneeEmail: assignee,
      notes: notes,
    );

void main() {
  group('템플릿 치환', () {
    test('자리표시자가 문의 정보로 바뀐다', () {
      const template = ReplyTemplate(
        id: 't-1',
        title: '기본 인사',
        body: '{보호자} 님, "{문의제목}" 문의 주셔서 감사합니다.',
      );

      expect(
        template.renderFor(_detail()),
        '김보호자 님, "별가루가 안 들어와요" 문의 주셔서 감사합니다.',
      );
    });

    test('자리표시자가 없으면 원문 그대로다', () {
      const template = ReplyTemplate(id: 't-1', title: '인사', body: '안녕하세요.');
      expect(template.renderFor(_detail()), '안녕하세요.');
    });

    test('같은 자리표시자가 여러 번 나와도 전부 바뀐다', () {
      const template = ReplyTemplate(
        id: 't-1',
        title: '인사',
        body: '{보호자} 님, {보호자} 님의 문의입니다.',
      );
      expect(template.renderFor(_detail()), '김보호자 님, 김보호자 님의 문의입니다.');
    });
  });

  group('기다린 시간', () {
    final created = DateTime(2026, 8, 13, 9, 0);

    InquirySummary summary(InquiryStatus status) => InquirySummary(
      id: 'inq-1',
      parentId: 'p-1',
      parentName: '김보호자',
      category: InquiryCategory.etc,
      title: '제목',
      status: status,
      answered: false,
      createdAt: created,
    );

    test('답변 대기면 접수 시점부터의 경과를 준다', () {
      final waiting = summary(InquiryStatus.pending)
          .waitingSince(DateTime(2026, 8, 16, 9, 0));
      expect(waiting, const Duration(days: 3));
    });

    test('답변이 끝난 문의는 null 이다', () {
      expect(
        summary(InquiryStatus.answered).waitingSince(DateTime(2026, 8, 16)),
        isNull,
      );
    });

    test('시계가 어긋나 미래 접수로 보여도 음수가 되지 않는다', () {
      final waiting = summary(InquiryStatus.pending)
          .waitingSince(DateTime(2026, 8, 13, 8, 0));
      expect(waiting, Duration.zero);
    });
  });

  group('상세 ViewModel', () {
    late _MockSupportRepository repository;
    late InquiryDetailViewModel viewModel;

    setUp(() {
      repository = _MockSupportRepository();
      viewModel = InquiryDetailViewModel(
        getInquiry: GetInquiryUseCase(repository),
        answerInquiry: AnswerInquiryUseCase(repository),
        updateAnswer: UpdateAnswerUseCase(repository),
        closeInquiry: CloseInquiryUseCase(repository),
        reopenInquiry: ReopenInquiryUseCase(repository),
        assignInquiry: AssignInquiryUseCase(repository),
        unassignInquiry: UnassignInquiryUseCase(repository),
        addNote: AddInquiryNoteUseCase(repository),
        getTemplates: GetReplyTemplatesUseCase(repository),
        saveTemplate: SaveReplyTemplateUseCase(repository),
        deleteTemplate: DeleteReplyTemplateUseCase(repository),
        inquiryId: 'inq-1',
      );
    });

    test('담당을 잡으면 서버를 부르고 화면을 다시 읽는다', () async {
      when(() => repository.getInquiry('inq-1'))
          .thenAnswer((_) async => _detail(assignee: 'me@goodquestion.kr'));
      when(() => repository.getTemplates()).thenAnswer((_) async => const []);
      when(() => repository.assignToMe('inq-1')).thenAnswer((_) async {});

      final ok = await viewModel.assignToMe();

      expect(ok, isTrue);
      verify(() => repository.assignToMe('inq-1')).called(1);
      expect(viewModel.inquiry?.assigneeEmail, 'me@goodquestion.kr');
    });

    test('빈 메모는 서버에 보내지 않는다', () async {
      final ok = await viewModel.addNote('   ');

      expect(ok, isFalse);
      verifyNever(
        () => repository.addNote(
          inquiryId: any(named: 'inquiryId'),
          body: any(named: 'body'),
        ),
      );
    });

    test('템플릿 조회가 실패해도 문의는 뜬다', () async {
      // 템플릿은 편의 기능이다. 그것 때문에 문의 화면이 통째로 죽으면 안 된다.
      when(() => repository.getInquiry('inq-1'))
          .thenAnswer((_) async => _detail());
      when(() => repository.getTemplates()).thenThrow(Exception('서버 오류'));

      await viewModel.load();

      expect(viewModel.state, ViewState.success);
      expect(viewModel.inquiry, isNotNull);
      expect(viewModel.templates, isEmpty);
    });
  });
}

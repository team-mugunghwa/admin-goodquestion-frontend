import '../../../../core/presentation/base_view_model.dart';
import '../../domain/entities/inquiry.dart';
import '../../domain/usecases/support_use_cases.dart';

class InquiryDetailViewModel extends BaseViewModel {
  InquiryDetailViewModel({
    required GetInquiryUseCase getInquiry,
    required AnswerInquiryUseCase answerInquiry,
    required UpdateAnswerUseCase updateAnswer,
    required CloseInquiryUseCase closeInquiry,
    required ReopenInquiryUseCase reopenInquiry,
    required AssignInquiryUseCase assignInquiry,
    required UnassignInquiryUseCase unassignInquiry,
    required AddInquiryNoteUseCase addNote,
    required GetReplyTemplatesUseCase getTemplates,
    required SaveReplyTemplateUseCase saveTemplate,
    required DeleteReplyTemplateUseCase deleteTemplate,
    required this.inquiryId,
  }) : _getInquiry = getInquiry,
       _answerInquiry = answerInquiry,
       _updateAnswer = updateAnswer,
       _closeInquiry = closeInquiry,
       _reopenInquiry = reopenInquiry,
       _assignInquiry = assignInquiry,
       _unassignInquiry = unassignInquiry,
       _addNote = addNote,
       _getTemplates = getTemplates,
       _saveTemplate = saveTemplate,
       _deleteTemplate = deleteTemplate;

  final GetInquiryUseCase _getInquiry;
  final AnswerInquiryUseCase _answerInquiry;
  final UpdateAnswerUseCase _updateAnswer;
  final CloseInquiryUseCase _closeInquiry;
  final ReopenInquiryUseCase _reopenInquiry;
  final AssignInquiryUseCase _assignInquiry;
  final UnassignInquiryUseCase _unassignInquiry;
  final AddInquiryNoteUseCase _addNote;
  final GetReplyTemplatesUseCase _getTemplates;
  final SaveReplyTemplateUseCase _saveTemplate;
  final DeleteReplyTemplateUseCase _deleteTemplate;

  final String inquiryId;

  InquiryDetail? _inquiry;
  List<ReplyTemplate> _templates = const [];

  InquiryDetail? get inquiry => _inquiry;

  /// 답변 템플릿. 문의와 함께 불러와 답변 칸 옆에서 바로 고를 수 있게 합니다.
  List<ReplyTemplate> get templates => _templates;

  Future<void> load() => guard(() async {
    // 템플릿이 실패해도 문의는 봐야 하므로 따로 삼킨다 - 템플릿은 편의 기능이다.
    _inquiry = await _getInquiry(inquiryId);
    try {
      _templates = await _getTemplates();
    } catch (_) {
      _templates = const [];
    }
  });

  /// 답변 등록. 서버가 알림과 푸시까지 함께 처리합니다.
  Future<bool> submitAnswer(String content) async {
    final ok = await runTask(
      () => _answerInquiry(inquiryId: inquiryId, content: content),
    );
    // 성공하든 실패하든 서버 상태를 다시 읽습니다. 성공했는데 화면이 예전 상태로
    // 남아 있으면 답변을 한 번 더 등록하려다 409 를 봅니다.
    await load();
    return ok;
  }

  /// 답변 수정. 알림은 다시 나가지 않습니다.
  Future<bool> editAnswer(String content) async {
    final ok = await runTask(
      () => _updateAnswer(inquiryId: inquiryId, content: content),
    );
    await load();
    return ok;
  }

  Future<bool> close() async {
    final ok = await runTask(() => _closeInquiry(inquiryId));
    await load();
    return ok;
  }

  Future<bool> reopen() async {
    final ok = await runTask(() => _reopenInquiry(inquiryId));
    await load();
    return ok;
  }

  /// 문의를 나에게 배정합니다. 이미 잡힌 문의를 넘겨받는 것도 이 호출입니다.
  Future<bool> assignToMe() async {
    final ok = await runTask(() => _assignInquiry(inquiryId));
    await load();
    return ok;
  }

  Future<bool> unassign() async {
    final ok = await runTask(() => _unassignInquiry(inquiryId));
    await load();
    return ok;
  }

  Future<bool> addNote(String body) async {
    final trimmed = body.trim();
    if (trimmed.isEmpty) return false;
    final ok = await runTask(
      () => _addNote(inquiryId: inquiryId, body: trimmed),
    );
    await load();
    return ok;
  }

  /// 템플릿 저장. [id] 가 null 이면 새로 만듭니다.
  Future<bool> saveTemplate({
    String? id,
    required String title,
    required String body,
  }) async {
    final ok = await runTask(
      () => _saveTemplate(id: id, title: title.trim(), body: body),
    );
    if (ok) {
      _templates = await _getTemplates();
      safeNotify();
    }
    return ok;
  }

  Future<bool> deleteTemplate(String id) async {
    final ok = await runTask(() => _deleteTemplate(id));
    if (ok) {
      _templates = await _getTemplates();
      safeNotify();
    }
    return ok;
  }
}

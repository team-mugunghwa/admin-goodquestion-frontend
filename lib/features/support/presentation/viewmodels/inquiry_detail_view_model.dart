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
    required this.inquiryId,
  }) : _getInquiry = getInquiry,
       _answerInquiry = answerInquiry,
       _updateAnswer = updateAnswer,
       _closeInquiry = closeInquiry,
       _reopenInquiry = reopenInquiry;

  final GetInquiryUseCase _getInquiry;
  final AnswerInquiryUseCase _answerInquiry;
  final UpdateAnswerUseCase _updateAnswer;
  final CloseInquiryUseCase _closeInquiry;
  final ReopenInquiryUseCase _reopenInquiry;

  final String inquiryId;

  InquiryDetail? _inquiry;
  InquiryDetail? get inquiry => _inquiry;

  Future<void> load() => guard(() async {
    _inquiry = await _getInquiry(inquiryId);
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
}

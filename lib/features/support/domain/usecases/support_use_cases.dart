import '../../../../core/network/page_result.dart';
import '../entities/inquiry.dart';
import '../repositories/support_repository.dart';

/// 고객센터 UseCase 모음.

class GetInquiriesUseCase {
  const GetInquiriesUseCase(this._repository);
  final SupportRepository _repository;

  Future<PageResult<InquirySummary>> call({
    InquiryStatus? status,
    InquiryCategory? category,
    String? keyword,
    int page = 0,
    int size = 20,
  }) => _repository.getInquiries(
    status: status,
    category: category,
    keyword: keyword,
    page: page,
    size: size,
  );
}

class GetInquiryUseCase {
  const GetInquiryUseCase(this._repository);
  final SupportRepository _repository;

  Future<InquiryDetail> call(String inquiryId) =>
      _repository.getInquiry(inquiryId);
}

/// 답변 등록. 사용자 알림과 푸시가 서버에서 함께 나갑니다.
class AnswerInquiryUseCase {
  const AnswerInquiryUseCase(this._repository);
  final SupportRepository _repository;

  Future<InquiryAnswer> call({
    required String inquiryId,
    required String content,
  }) => _repository.answer(inquiryId: inquiryId, content: content);
}

/// 답변 수정. 알림은 다시 나가지 않습니다.
class UpdateAnswerUseCase {
  const UpdateAnswerUseCase(this._repository);
  final SupportRepository _repository;

  Future<InquiryAnswer> call({
    required String inquiryId,
    required String content,
  }) => _repository.updateAnswer(inquiryId: inquiryId, content: content);
}

class CloseInquiryUseCase {
  const CloseInquiryUseCase(this._repository);
  final SupportRepository _repository;

  Future<void> call(String inquiryId) => _repository.close(inquiryId);
}

class ReopenInquiryUseCase {
  const ReopenInquiryUseCase(this._repository);
  final SupportRepository _repository;

  Future<void> call(String inquiryId) => _repository.reopen(inquiryId);
}

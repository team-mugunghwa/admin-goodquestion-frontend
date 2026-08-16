import '../../../../core/network/page_result.dart';
import '../entities/inquiry.dart';

abstract class SupportRepository {
  Future<PageResult<InquirySummary>> getInquiries({
    InquiryStatus? status,
    InquiryCategory? category,
    String? keyword,
    int page = 0,
    int size = 20,
  });

  Future<InquiryDetail> getInquiry(String inquiryId);

  /// 답변을 등록합니다.
  ///
  /// **서버가 이 호출 하나로 세 가지를 합니다**: 답변 저장, 문의 상태 변경,
  /// 사용자 알림 생성. 알림이 커밋되면 FCM 푸시가 나갑니다. 화면에서 따로
  /// "알림 보내기"를 부르지 않는 이유입니다.
  Future<InquiryAnswer> answer({
    required String inquiryId,
    required String content,
  });

  /// 답변 내용을 고칩니다. **알림은 다시 나가지 않습니다** - 오타를 고칠 때마다
  /// 사용자 기기에 푸시가 울리면 알림 자체가 무시됩니다.
  Future<InquiryAnswer> updateAnswer({
    required String inquiryId,
    required String content,
  });

  Future<void> close(String inquiryId);

  Future<void> reopen(String inquiryId);

  /// 문의를 나에게 배정합니다. 이미 잡힌 문의를 넘겨받는 것도 이 호출입니다.
  Future<void> assignToMe(String inquiryId);

  Future<void> unassign(String inquiryId);

  /// 내부 메모를 남깁니다. 수정과 삭제가 없습니다.
  Future<InquiryNote> addNote({required String inquiryId, required String body});

  Future<List<ReplyTemplate>> getTemplates();

  /// [id] 가 null 이면 생성, 있으면 수정입니다.
  Future<ReplyTemplate> saveTemplate({
    String? id,
    required String title,
    required String body,
  });

  Future<void> deleteTemplate(String id);
}

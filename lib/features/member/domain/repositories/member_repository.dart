import '../../../../core/network/page_result.dart';
import '../entities/member.dart';

abstract class MemberRepository {
  Future<PageResult<MemberSummary>> getMembers({
    MemberStatus? status,
    String? keyword,
    int page = 0,
    int size = 20,
  });

  Future<MemberDetail> getMember(String parentId);

  Future<PageResult<StorySessionSummary>> getStorySessions({
    required String parentId,
    int page = 0,
    int size = 20,
  });

  /// 계정을 막습니다. 서버가 로그인 세션도 함께 끊습니다.
  ///
  /// [reason] 은 필수입니다. 사유 없이 막으면 나중에 왜 막았는지 아무도 모릅니다.
  Future<MemberDetail> suspend({
    required String parentId,
    required String reason,
  });

  Future<MemberDetail> restore(String parentId);

  /// 로그인 세션만 끊습니다. 계정은 그대로라 다시 로그인할 수 있습니다.
  Future<void> revokeLoginSessions(String parentId);
}

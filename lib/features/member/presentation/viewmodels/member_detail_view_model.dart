import '../../../../core/config/app_config.dart';
import '../../../../core/network/page_result.dart';
import '../../../../core/presentation/base_view_model.dart';
import '../../domain/entities/member.dart';
import '../../domain/usecases/member_use_cases.dart';

class MemberDetailViewModel extends BaseViewModel {
  MemberDetailViewModel({
    required GetMemberUseCase getMember,
    required GetStorySessionsUseCase getStorySessions,
    required SuspendMemberUseCase suspendMember,
    required RestoreMemberUseCase restoreMember,
    required RevokeLoginSessionsUseCase revokeLoginSessions,
    required this.parentId,
  }) : _getMember = getMember,
       _getStorySessions = getStorySessions,
       _suspendMember = suspendMember,
       _restoreMember = restoreMember,
       _revokeLoginSessions = revokeLoginSessions;

  final GetMemberUseCase _getMember;
  final GetStorySessionsUseCase _getStorySessions;
  final SuspendMemberUseCase _suspendMember;
  final RestoreMemberUseCase _restoreMember;
  final RevokeLoginSessionsUseCase _revokeLoginSessions;

  final String parentId;

  MemberDetail? _member;
  PageResult<StorySessionSummary> _sessions = const PageResult.empty();

  MemberDetail? get member => _member;
  PageResult<StorySessionSummary> get sessions => _sessions;

  /// 사용자 정보와 학습 세션을 함께 받아 옵니다.
  ///
  /// 순차로 부르면 두 번의 왕복이 그대로 더해집니다. 둘은 서로를 필요로 하지 않아
  /// 같이 보내도 됩니다.
  Future<void> load() => guard(() async {
    final results = await Future.wait([
      _getMember(parentId),
      _getStorySessions(parentId: parentId, size: AppConfig.defaultPageSize),
    ]);
    _member = results[0] as MemberDetail;
    _sessions = results[1] as PageResult<StorySessionSummary>;
  });

  Future<void> loadSessions({int page = 0}) async {
    await runTask(() async {
      _sessions = await _getStorySessions(
        parentId: parentId,
        page: page,
        size: AppConfig.defaultPageSize,
      );
    });
  }

  Future<bool> suspend(String reason) async {
    final ok = await runTask(() async {
      _member = await _suspendMember(parentId: parentId, reason: reason);
    });
    return ok;
  }

  Future<bool> restore() async {
    final ok = await runTask(() async {
      _member = await _restoreMember(parentId);
    });
    return ok;
  }

  Future<bool> revokeLoginSessions() async {
    final ok = await runTask(() => _revokeLoginSessions(parentId));
    if (ok) {
      // 세션 목록은 상세 응답에 들어 있습니다. 끊고 나서 다시 읽어야 화면이
      // "끊긴 상태"를 보여줍니다.
      _member = await _getMember(parentId);
      safeNotify();
    }
    return ok;
  }
}

import '../../../../core/network/page_result.dart';
import '../entities/member.dart';
import '../repositories/member_repository.dart';

/// 사용자 관리 UseCase 모음.

class GetMembersUseCase {
  const GetMembersUseCase(this._repository);
  final MemberRepository _repository;

  Future<PageResult<MemberSummary>> call({
    MemberStatus? status,
    String? keyword,
    int page = 0,
    int size = 20,
  }) => _repository.getMembers(
    status: status,
    keyword: keyword,
    page: page,
    size: size,
  );
}

class GetMemberUseCase {
  const GetMemberUseCase(this._repository);
  final MemberRepository _repository;

  Future<MemberDetail> call(String parentId) => _repository.getMember(parentId);
}

class GetStorySessionsUseCase {
  const GetStorySessionsUseCase(this._repository);
  final MemberRepository _repository;

  Future<PageResult<StorySessionSummary>> call({
    required String parentId,
    int page = 0,
    int size = 20,
  }) => _repository.getStorySessions(
    parentId: parentId,
    page: page,
    size: size,
  );
}

class SuspendMemberUseCase {
  const SuspendMemberUseCase(this._repository);
  final MemberRepository _repository;

  Future<MemberDetail> call({
    required String parentId,
    required String reason,
  }) => _repository.suspend(parentId: parentId, reason: reason);
}

class RestoreMemberUseCase {
  const RestoreMemberUseCase(this._repository);
  final MemberRepository _repository;

  Future<MemberDetail> call(String parentId) => _repository.restore(parentId);
}

class RevokeLoginSessionsUseCase {
  const RevokeLoginSessionsUseCase(this._repository);
  final MemberRepository _repository;

  Future<void> call(String parentId) =>
      _repository.revokeLoginSessions(parentId);
}

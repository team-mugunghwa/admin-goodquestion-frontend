import '../../../../core/config/app_config.dart';
import '../../../../core/network/page_result.dart';
import '../../../../core/presentation/base_view_model.dart';
import '../../domain/entities/member.dart';
import '../../domain/usecases/member_use_cases.dart';

class MemberListViewModel extends BaseViewModel {
  MemberListViewModel(this._getMembers);

  final GetMembersUseCase _getMembers;

  PageResult<MemberSummary> _members = const PageResult.empty();
  MemberStatus? _status;
  String _keyword = '';

  PageResult<MemberSummary> get members => _members;
  MemberStatus? get status => _status;
  String get keyword => _keyword;

  Future<void> load({int page = 0}) => guard(() async {
    _members = await _getMembers(
      status: _status,
      keyword: _keyword,
      page: page,
      size: AppConfig.defaultPageSize,
    );
  });

  Future<void> changeStatus(MemberStatus? status) {
    _status = status;
    return load();
  }

  Future<void> search(String keyword) {
    _keyword = keyword.trim();
    return load();
  }
}

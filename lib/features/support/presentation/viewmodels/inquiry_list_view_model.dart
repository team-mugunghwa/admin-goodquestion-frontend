import '../../../../core/config/app_config.dart';
import '../../../../core/network/page_result.dart';
import '../../../../core/presentation/base_view_model.dart';
import '../../domain/entities/inquiry.dart';
import '../../domain/usecases/support_use_cases.dart';

class InquiryListViewModel extends BaseViewModel {
  InquiryListViewModel(this._getInquiries);

  final GetInquiriesUseCase _getInquiries;

  PageResult<InquirySummary> _inquiries = const PageResult.empty();

  /// 처음 여는 화면은 미답변만 보여줍니다. 고객센터 메뉴를 여는 이유는 대개
  /// "답변할 것이 있는가"이고, 전체를 보여주면 그 안에서 다시 걸러야 합니다.
  InquiryStatus? _status = InquiryStatus.pending;
  InquiryCategory? _category;
  String _keyword = '';

  PageResult<InquirySummary> get inquiries => _inquiries;
  InquiryStatus? get status => _status;
  InquiryCategory? get category => _category;
  String get keyword => _keyword;

  Future<void> load({int page = 0}) => guard(() async {
    _inquiries = await _getInquiries(
      status: _status,
      category: _category,
      keyword: _keyword,
      page: page,
      size: AppConfig.defaultPageSize,
    );
  });

  Future<void> changeStatus(InquiryStatus? status) {
    _status = status;
    return load();
  }

  Future<void> changeCategory(InquiryCategory? category) {
    _category = category;
    return load();
  }

  Future<void> search(String keyword) {
    _keyword = keyword.trim();
    return load();
  }
}

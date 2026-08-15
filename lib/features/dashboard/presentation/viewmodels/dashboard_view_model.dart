import '../../../../core/presentation/base_view_model.dart';
import '../../domain/entities/dashboard_summary.dart';
import '../../domain/usecases/get_dashboard_summary_use_case.dart';

class DashboardViewModel extends BaseViewModel {
  DashboardViewModel(this._getSummary);

  final GetDashboardSummaryUseCase _getSummary;

  DashboardSummary? _summary;
  DashboardSummary? get summary => _summary;

  Future<void> load() => guard(() async {
    _summary = await _getSummary();
  });
}

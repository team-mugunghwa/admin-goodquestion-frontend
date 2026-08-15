import '../entities/dashboard_summary.dart';

abstract class DashboardRepository {
  /// 대시보드 전체를 한 번에 받아 옵니다.
  ///
  /// 카드마다 호출을 나누면 첫 화면에서 요청이 예닐곱 개 나가고, 그중 하나가
  /// 느리면 화면이 조각조각 채워집니다. 서버도 한 번에 내리도록 되어 있습니다.
  Future<DashboardSummary> getSummary();
}

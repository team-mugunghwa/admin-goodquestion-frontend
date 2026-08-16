import '../../../../core/presentation/base_view_model.dart';
import '../../domain/entities/db_schema.dart';
import '../../domain/usecases/database_use_cases.dart';

class DatabaseListViewModel extends BaseViewModel {
  DatabaseListViewModel(this._getTables);

  final GetTablesUseCase _getTables;

  List<DbTableSummary> _tables = const [];
  String _keyword = '';

  String get keyword => _keyword;

  /// 검색어에 걸린 테이블만. 이름뿐 아니라 **설명도 함께 찾습니다.**
  ///
  /// 찾는 사람은 테이블 이름을 모르는 경우가 많습니다. "별가루"로 검색했을 때
  /// `stardust_wallets` 가 나와야 쓸모가 있습니다.
  List<DbTableSummary> get tables {
    if (_keyword.isEmpty) return _tables;
    final needle = _keyword.toLowerCase();
    return _tables
        .where(
          (table) =>
              table.name.toLowerCase().contains(needle) ||
              (table.comment ?? '').toLowerCase().contains(needle) ||
              table.group.contains(_keyword),
        )
        .toList();
  }

  /// 분류별로 묶은 목록. 서버가 이미 분류 순서로 정렬해 주므로 나누기만 합니다.
  Map<String, List<DbTableSummary>> get grouped {
    final map = <String, List<DbTableSummary>>{};
    for (final table in tables) {
      map.putIfAbsent(table.group, () => []).add(table);
    }
    return map;
  }

  int get totalCount => _tables.length;

  Future<void> load() => guard(() async {
    _tables = await _getTables();
  });

  /// 서버를 다시 부르지 않습니다. 테이블 목록은 40개 남짓이라 전부 받아 두고
  /// 화면에서 거르는 편이 타이핑할 때마다 왕복하는 것보다 빠릅니다.
  void search(String keyword) {
    _keyword = keyword.trim();
    safeNotify();
  }
}

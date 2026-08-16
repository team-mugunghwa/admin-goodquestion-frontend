import '../../../../core/presentation/base_view_model.dart';
import '../../domain/entities/db_schema.dart';
import '../../domain/usecases/database_use_cases.dart';

class TableDetailViewModel extends BaseViewModel {
  TableDetailViewModel({
    required GetTableUseCase getTable,
    required GetTableRowsUseCase getRows,
    required this.tableName,
  }) : _getTable = getTable,
       _getRows = getRows;

  final GetTableUseCase _getTable;
  final GetTableRowsUseCase _getRows;
  final String tableName;

  /// 한 번에 가져오는 행 수. 서버 상한은 200입니다.
  static const int pageSize = 50;

  DbTableDetail? _detail;
  DbRowPage _rows = const DbRowPage.empty();
  String? _filterColumn;
  String _keyword = '';
  String? _sortColumn;
  String _sortDirection = 'desc';

  DbTableDetail? get detail => _detail;
  DbRowPage get rows => _rows;
  String? get filterColumn => _filterColumn;
  String get keyword => _keyword;
  String? get sortColumn => _sortColumn;
  String get sortDirection => _sortDirection;

  /// 구조와 값을 함께 받아 옵니다. 둘은 서로를 필요로 하지 않아 같이 보내도 됩니다.
  Future<void> load() => guard(() async {
    final results = await Future.wait([
      _getTable(tableName),
      _getRows(tableName: tableName, size: pageSize),
    ]);
    _detail = results[0] as DbTableDetail;
    _rows = results[1] as DbRowPage;
  });

  Future<void> loadRows({int page = 0}) async {
    await runTask(() async {
      _rows = await _getRows(
        tableName: tableName,
        page: page,
        size: pageSize,
        sortColumn: _sortColumn,
        sortDirection: _sortDirection,
        filterColumn: _filterColumn,
        keyword: _keyword,
      );
    });
  }

  /// 검색 조건을 바꾸면 첫 페이지로 돌아갑니다. 3페이지를 보다가 조건을 좁히면
  /// 결과가 한 페이지뿐일 수 있는데, 그때 3페이지에 머물면 빈 화면이 뜹니다.
  Future<void> search({String? column, required String keyword}) {
    _filterColumn = column;
    _keyword = keyword.trim();
    return loadRows();
  }

  /// 같은 컬럼을 다시 누르면 방향만 뒤집습니다.
  Future<void> sortBy(String column) {
    if (_sortColumn == column) {
      _sortDirection = _sortDirection == 'asc' ? 'desc' : 'asc';
    } else {
      _sortColumn = column;
      _sortDirection = 'asc';
    }
    return loadRows();
  }
}

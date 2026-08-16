import '../entities/db_schema.dart';
import '../repositories/database_repository.dart';

/// 데이터 탐색 UseCase 모음.

class GetTablesUseCase {
  const GetTablesUseCase(this._repository);
  final DatabaseRepository _repository;

  Future<List<DbTableSummary>> call() => _repository.getTables();
}

class GetTableUseCase {
  const GetTableUseCase(this._repository);
  final DatabaseRepository _repository;

  Future<DbTableDetail> call(String tableName) => _repository.getTable(tableName);
}

class GetTableRowsUseCase {
  const GetTableRowsUseCase(this._repository);
  final DatabaseRepository _repository;

  Future<DbRowPage> call({
    required String tableName,
    int page = 0,
    int size = 50,
    String? sortColumn,
    String? sortDirection,
    String? filterColumn,
    String? keyword,
  }) => _repository.getRows(
    tableName: tableName,
    page: page,
    size: size,
    sortColumn: sortColumn,
    sortDirection: sortDirection,
    filterColumn: filterColumn,
    keyword: keyword,
  );
}

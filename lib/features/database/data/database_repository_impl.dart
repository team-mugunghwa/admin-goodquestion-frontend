import '../../../core/error/exceptions.dart';
import '../../../core/error/failure.dart';
import '../../../core/network/dio_client.dart';
import '../domain/entities/db_schema.dart';
import '../domain/repositories/database_repository.dart';

class DatabaseRepositoryImpl implements DatabaseRepository {
  const DatabaseRepositoryImpl(this._client);

  final DioClient _client;

  @override
  Future<List<DbTableSummary>> getTables() => _guard(
    () => _client.get(
      '/database/tables',
      parse: (data) => data is List
          ? data.whereType<Map<String, dynamic>>().map(_toSummary).toList()
          : const <DbTableSummary>[],
    ),
  );

  @override
  Future<DbTableDetail> getTable(String tableName) => _guard(
    () => _client.get(
      '/database/tables/$tableName',
      parse: (data) => _toDetail(_asMap(data)),
    ),
  );

  @override
  Future<DbRowPage> getRows({
    required String tableName,
    int page = 0,
    int size = 50,
    String? sortColumn,
    String? sortDirection,
    String? filterColumn,
    String? keyword,
  }) => _guard(
    () => _client.get(
      '/database/tables/$tableName/rows',
      queryParameters: {
        'page': page,
        'size': size,
        if (sortColumn != null) 'sortColumn': sortColumn,
        if (sortDirection != null) 'sortDirection': sortDirection,
        if (filterColumn != null && keyword != null && keyword.isNotEmpty) ...{
          'filterColumn': filterColumn,
          'keyword': keyword,
        },
      },
      parse: (data) => _toRowPage(_asMap(data)),
    ),
  );

  static DbTableSummary _toSummary(Map<String, dynamic> json) => DbTableSummary(
    name: json['name'] as String,
    comment: json['comment'] as String?,
    group: json['group'] as String? ?? '기타',
    columnCount: (json['columnCount'] as num?)?.toInt() ?? 0,
    estimatedRows: (json['estimatedRows'] as num?)?.toInt(),
    containsPersonalData: json['containsPersonalData'] as bool? ?? false,
  );

  static DbColumn _toColumn(Map<String, dynamic> json) => DbColumn(
    position: (json['position'] as num?)?.toInt() ?? 0,
    name: json['name'] as String,
    type: json['type'] as String? ?? '',
    nullable: json['nullable'] as bool? ?? true,
    defaultValue: json['defaultValue'] as String?,
    comment: json['comment'] as String?,
    primaryKey: json['primaryKey'] as bool? ?? false,
    masked: json['masked'] as bool? ?? false,
    referencesTable: json['referencesTable'] as String?,
    referencesColumn: json['referencesColumn'] as String?,
  );

  static DbTableDetail _toDetail(Map<String, dynamic> json) => DbTableDetail(
    name: json['name'] as String,
    comment: json['comment'] as String?,
    group: json['group'] as String? ?? '기타',
    rowCount: (json['rowCount'] as num?)?.toInt() ?? 0,
    containsPersonalData: json['containsPersonalData'] as bool? ?? false,
    columns: _columnList(json['columns']),
    indexes: (json['indexes'] as List? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(
          (index) => DbIndex(
            name: index['name'] as String? ?? '',
            definition: index['definition'] as String? ?? '',
            unique: index['unique'] as bool? ?? false,
            primaryKey: index['primaryKey'] as bool? ?? false,
          ),
        )
        .toList(),
  );

  static DbRowPage _toRowPage(Map<String, dynamic> json) => DbRowPage(
    columns: _columnList(json['columns']),
    rows: (json['rows'] as List? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(Map<String, Object?>.from)
        .toList(),
    page: (json['page'] as num?)?.toInt() ?? 0,
    size: (json['size'] as num?)?.toInt() ?? 0,
    totalElements: (json['totalElements'] as num?)?.toInt() ?? 0,
    totalPages: (json['totalPages'] as num?)?.toInt() ?? 0,
  );

  static List<DbColumn> _columnList(Object? value) => value is List
      ? value.whereType<Map<String, dynamic>>().map(_toColumn).toList()
      : const [];

  static Map<String, dynamic> _asMap(Object? data) {
    if (data is Map<String, dynamic>) return data;
    throw const ParseException();
  }

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on AppException catch (e) {
      throw Failure.fromException(e);
    }
  }
}

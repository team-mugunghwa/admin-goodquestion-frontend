/// 목록에 보이는 테이블 한 줄.
class DbTableSummary {
  const DbTableSummary({
    required this.name,
    required this.group,
    required this.columnCount,
    required this.containsPersonalData,
    this.comment,
    this.estimatedRows,
  });

  final String name;

  /// 테이블이 무엇을 담는지. DB 에 심어 둔 설명을 그대로 읽어 옵니다.
  final String? comment;

  /// 도메인 분류. 서버가 정해 줍니다.
  final String group;
  final int columnCount;

  /// 대략적인 행 수. 정확한 값이 아니라 통계 기반 추정치입니다.
  /// 한 번도 통계를 낸 적 없는 테이블은 null 입니다.
  final int? estimatedRows;

  /// 개인정보가 들어 있는 테이블인지. 열기 전에 알려 주려고 받습니다.
  final bool containsPersonalData;
}

class DbColumn {
  const DbColumn({
    required this.position,
    required this.name,
    required this.type,
    required this.nullable,
    required this.primaryKey,
    required this.masked,
    this.defaultValue,
    this.comment,
    this.referencesTable,
    this.referencesColumn,
  });

  final int position;
  final String name;

  /// varchar(50), uuid, timestamptz 처럼 개발자가 쓰는 표기입니다.
  final String type;
  final bool nullable;
  final String? defaultValue;
  final String? comment;
  final bool primaryKey;

  /// 값을 가려서 내려주는 컬럼인지. 비밀번호와 토큰이 해당합니다.
  final bool masked;

  /// 이 컬럼이 가리키는 다른 테이블. 없으면 null 입니다.
  final String? referencesTable;
  final String? referencesColumn;

  bool get isForeignKey => referencesTable != null;
}

class DbIndex {
  const DbIndex({
    required this.name,
    required this.definition,
    required this.unique,
    required this.primaryKey,
  });

  final String name;
  final String definition;
  final bool unique;
  final bool primaryKey;
}

class DbTableDetail {
  const DbTableDetail({
    required this.name,
    required this.group,
    required this.rowCount,
    required this.containsPersonalData,
    required this.columns,
    required this.indexes,
    this.referencedBy = const [],
    this.comment,
  });

  final String name;
  final String? comment;
  final String group;

  /// 정확한 행 수. 목록의 추정치와 달리 실제로 센 값입니다.
  final int rowCount;
  final bool containsPersonalData;
  final List<DbColumn> columns;
  final List<DbIndex> indexes;

  /// 이 테이블을 가리키는 곳. 지울 때 무엇이 걸리는지 알려면 필요합니다.
  final List<DbIncomingReference> referencedBy;
}

/// 실제 저장된 값 한 페이지.
class DbRowPage {
  const DbRowPage({
    required this.columns,
    required this.rows,
    required this.page,
    required this.size,
    required this.totalElements,
    required this.totalPages,
  });

  const DbRowPage.empty()
    : columns = const [],
      rows = const [],
      page = 0,
      size = 0,
      totalElements = 0,
      totalPages = 0;

  /// 열 순서와 가림 여부. 값이 비어 있는 컬럼도 표에서 사라지지 않도록 함께 받습니다.
  final List<DbColumn> columns;

  /// 컬럼 이름을 키로 하는 값 묶음.
  final List<Map<String, Object?>> rows;

  final int page;
  final int size;
  final int totalElements;
  final int totalPages;

  bool get isEmpty => rows.isEmpty;
  bool get hasPrevious => page > 0;
  bool get hasNext => page + 1 < totalPages;
}

/// 관계도의 상자 하나.
class DbTableNode {
  const DbTableNode({
    required this.name,
    required this.group,
    required this.columnCount,
    required this.containsPersonalData,
    required this.keyColumns,
    this.comment,
  });

  final String name;
  final String? comment;
  final String group;
  final int columnCount;
  final bool containsPersonalData;

  /// 기본키와 외래키만. 관계를 읽는 데 필요한 것이 이 둘입니다.
  final List<DbKeyColumn> keyColumns;

  /// 상자에 크게 적을 이름. 설명이 있으면 설명의 첫 문장을 씁니다.
  String get title => comment == null ? name : comment!.split('.').first;
}

class DbKeyColumn {
  const DbKeyColumn({
    required this.name,
    required this.primaryKey,
    required this.foreignKey,
  });

  final String name;
  final bool primaryKey;
  final bool foreignKey;
}

/// 관계 하나. 외래키 한 쌍입니다.
class DbRelation {
  const DbRelation({
    required this.fromTable,
    required this.fromColumn,
    required this.toTable,
    required this.toColumn,
    required this.optional,
  });

  /// 가리키는 쪽. 여러 건이 있을 수 있는 "N" 입니다.
  final String fromTable;
  final String fromColumn;

  /// 가리켜지는 쪽. 하나뿐인 "1" 입니다.
  final String toTable;
  final String toColumn;

  /// 참조하는 컬럼이 null 을 받는지. 받으면 없을 수도 있는 관계입니다.
  final bool optional;

  bool touches(String table) => fromTable == table || toTable == table;
}

/// 관계도 전체.
class DbSchemaGraph {
  const DbSchemaGraph({required this.tables, required this.relations});

  const DbSchemaGraph.empty() : tables = const [], relations = const [];

  final List<DbTableNode> tables;
  final List<DbRelation> relations;

  bool get isEmpty => tables.isEmpty;
}

/// 이 테이블을 가리키는 쪽.
class DbIncomingReference {
  const DbIncomingReference({required this.table, required this.column});

  final String table;
  final String column;
}

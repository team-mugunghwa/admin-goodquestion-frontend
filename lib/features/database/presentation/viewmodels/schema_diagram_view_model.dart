import '../../../../core/presentation/base_view_model.dart';
import '../../domain/entities/db_schema.dart';
import '../../domain/usecases/database_use_cases.dart';
import '../diagram/schema_layout.dart';

class SchemaDiagramViewModel extends BaseViewModel {
  SchemaDiagramViewModel(this._getRelations);

  final GetRelationsUseCase _getRelations;

  DbSchemaGraph _graph = const DbSchemaGraph.empty();
  DiagramLayout _layout = const DiagramLayout.empty();
  String? _group;
  String? _focusedTable;
  bool _hideIsolated = false;

  DbSchemaGraph get graph => _graph;
  DiagramLayout get layout => _layout;

  /// 보고 있는 분류. null 이면 전체입니다.
  String? get group => _group;

  /// 관계 없는 테이블을 숨기는 중인지.
  ///
  /// 기본은 끔입니다. 처음 온 사람에게는 "무엇이 있는가"가 전부 보이는 쪽이
  /// 맞고, 숨기기는 관계를 읽을 때 켜는 옵션입니다.
  bool get hideIsolated => _hideIsolated;

  /// 누른 상자. 이 상자에 닿는 선만 진하게 그립니다.
  String? get focusedTable => _focusedTable;

  List<String> get groups {
    // 서버가 이미 분류 순서로 정렬해서 주므로 순서를 유지한 채 중복만 없앱니다.
    final seen = <String>[];
    for (final table in _graph.tables) {
      if (!seen.contains(table.group)) seen.add(table.group);
    }
    return seen;
  }

  DbTableNode? get focusedNode {
    if (_focusedTable == null) return null;
    for (final table in _graph.tables) {
      if (table.name == _focusedTable) return table;
    }
    return null;
  }

  /// 누른 상자에 닿는 관계. 화면 아래에 글로도 적어 줍니다.
  ///
  /// 선만으로는 어느 컬럼이 이어진 것인지 알 수 없습니다.
  List<DbRelation> get focusedRelations {
    if (_focusedTable == null) return const [];
    return _graph.relations
        .where((relation) => relation.touches(_focusedTable!))
        .toList();
  }

  Future<void> load() => guard(() async {
    _graph = await _getRelations();
    _relayout();
  });

  void selectGroup(String? group) {
    _group = group;
    // 고른 분류에 없는 상자를 계속 눌린 채로 두면 아래 설명이 화면과 어긋납니다.
    if (_focusedTable != null &&
        !_layout.tables.any((table) => table.name == _focusedTable)) {
      _focusedTable = null;
    }
    _relayout();
    safeNotify();
  }

  void focus(String? tableName) {
    _focusedTable = _focusedTable == tableName ? null : tableName;
    safeNotify();
  }

  void toggleHideIsolated() {
    _hideIsolated = !_hideIsolated;
    _relayout();
    safeNotify();
  }

  void _relayout() {
    _layout = SchemaLayout.compute(
      _graph,
      group: _group,
      hideIsolated: _hideIsolated,
    );
    // 숨겨진 상자가 눌린 채로 남으면 아래 설명이 화면과 어긋납니다.
    if (_focusedTable != null &&
        !_layout.tables.any((table) => table.name == _focusedTable)) {
      _focusedTable = null;
    }
  }
}

import 'dart:ui';

import '../../domain/entities/db_schema.dart';

/// 배치가 끝난 상자 하나.
class PlacedTable {
  const PlacedTable({
    required this.node,
    required this.rect,
    required this.depth,
    required this.dimmed,
    required this.visibleKeyColumns,
    required this.hiddenKeyCount,
  });

  final DbTableNode node;
  final Rect rect;

  /// 왼쪽에서 몇 번째 칸인지. 0이 아무것도 참조하지 않는 뿌리입니다.
  final int depth;

  /// 고른 분류 밖이라 참고로만 보여 주는 상자인지.
  final bool dimmed;

  final List<DbKeyColumn> visibleKeyColumns;

  /// 자리에 다 담지 못해 접은 키 개수.
  final int hiddenKeyCount;

  String get name => node.name;
}

/// 배치가 끝난 선 하나.
class PlacedRelation {
  const PlacedRelation({
    required this.relation,
    required this.start,
    required this.end,
    required this.startsOnLeft,
    required this.endsOnLeft,
  });

  final DbRelation relation;

  /// 가리키는 쪽(N)에서 나가는 점.
  final Offset start;

  /// 가리켜지는 쪽(1)에 닿는 점.
  final Offset end;

  /// 선이 상자의 어느 면에서 나가고 닿는지. 까마귀발과 막대를 그릴 방향입니다.
  final bool startsOnLeft;
  final bool endsOnLeft;
}

class DiagramLayout {
  const DiagramLayout({
    required this.tables,
    required this.relations,
    required this.size,
  });

  const DiagramLayout.empty()
    : tables = const [],
      relations = const [],
      size = Size.zero;

  final List<PlacedTable> tables;
  final List<PlacedRelation> relations;

  /// 전체가 차지하는 크기. 화면이 이 크기로 캔버스를 잡습니다.
  final Size size;

  bool get isEmpty => tables.isEmpty;
}

/// 관계도의 배치를 정합니다.
///
/// ## 왜 서버가 아니라 여기서 정하나
///
/// 좌표는 화면 사정에 따라 계속 바뀝니다. 분류를 바꾸거나 접을 때마다 서버에
/// 다시 물으면 그때마다 왕복이 생깁니다. 서버는 상자와 선만 주고 배치는 여기서 합니다.
///
/// ## 어떻게 놓나
///
/// **가리켜지는 쪽을 왼쪽에 둡니다.** 아무것도 참조하지 않는 테이블(`parents`,
/// `topics`)이 맨 왼쪽 칸이고, 그것을 참조하는 테이블이 그다음 칸입니다. 그래서
/// 선이 대부분 오른쪽에서 왼쪽으로 흐르고, "무엇이 무엇에 딸려 있는지"가 가로
/// 위치만 봐도 읽힙니다. 아무렇게나 놓고 선을 이으면 40개 상자에서는 실타래가 됩니다.
abstract final class SchemaLayout {
  static const double nodeWidth = 224;
  static const double headerHeight = 46;
  static const double keyRowHeight = 15;
  static const double nodePaddingBottom = 8;

  /// 상자 테두리. 위아래 한 겹씩이 높이에 더해지므로 계산에 넣어야 합니다.
  /// 빼먹으면 안쪽 내용이 2픽셀 넘쳐 마지막 키 줄이 잘립니다.
  static const double borderWidth = 1;

  /// 상자에 적는 키의 최대 개수. 넘으면 접고 개수만 알립니다.
  static const int maxKeyRows = 6;

  static const double columnGap = 96;
  static const double rowGap = 26;
  static const double canvasPadding = 32;

  /// 참조가 서로 물릴 때 깊이 계산이 끝나지 않는 것을 막는 상한.
  static const int maxDepth = 12;

  static DiagramLayout compute(DbSchemaGraph graph, {String? group}) {
    if (graph.isEmpty) return const DiagramLayout.empty();

    final visible = _visibleTables(graph, group);
    if (visible.isEmpty) return const DiagramLayout.empty();

    final names = visible.map((table) => table.name).toSet();
    final relations = graph.relations
        .where(
          (relation) =>
              names.contains(relation.fromTable) &&
              names.contains(relation.toTable) &&
              // 자기 자신을 가리키는 관계는 상자 하나 안에서 끝나 배치에 영향이 없습니다.
              relation.fromTable != relation.toTable,
        )
        .toList();

    final depths = _depths(visible, relations);
    final placed = _place(visible, depths, group);
    final byName = {for (final table in placed) table.name: table};

    return DiagramLayout(
      tables: placed,
      relations: _connectAll(relations, byName),
      size: _canvasSize(placed),
    );
  }

  /// 분류를 고르면 그 분류와 **맞닿은 테이블까지** 보여 줍니다.
  ///
  /// 고른 분류만 남기면 경계에서 선이 끊깁니다. 학습 결과만 보는데 그것이 어느
  /// 아이의 것인지 안 보이면 반쪽짜리입니다. 밖에서 끌어온 상자는 흐리게 그립니다.
  static List<DbTableNode> _visibleTables(DbSchemaGraph graph, String? group) {
    if (group == null) return graph.tables;

    final core = graph.tables
        .where((table) => table.group == group)
        .map((table) => table.name)
        .toSet();
    if (core.isEmpty) return const [];

    final withNeighbours = {...core};
    for (final relation in graph.relations) {
      if (core.contains(relation.fromTable)) withNeighbours.add(relation.toTable);
      if (core.contains(relation.toTable)) withNeighbours.add(relation.fromTable);
    }
    return graph.tables
        .where((table) => withNeighbours.contains(table.name))
        .toList();
  }

  /// 참조하는 쪽이 참조되는 쪽보다 한 칸 오른쪽에 오도록 깊이를 매깁니다.
  static Map<String, int> _depths(
    List<DbTableNode> tables,
    List<DbRelation> relations,
  ) {
    final targets = <String, List<String>>{};
    for (final relation in relations) {
      targets.putIfAbsent(relation.fromTable, () => []).add(relation.toTable);
    }

    final depths = <String, int>{};
    final visiting = <String>{};

    int depthOf(String table) {
      final known = depths[table];
      if (known != null) return known;
      // 서로 물린 참조. 여기서 끊지 않으면 계산이 돌아오지 않습니다.
      if (!visiting.add(table)) return 0;

      var depth = 0;
      for (final target in targets[table] ?? const <String>[]) {
        depth = depth < depthOf(target) + 1 ? depthOf(target) + 1 : depth;
        if (depth >= maxDepth) {
          depth = maxDepth;
          break;
        }
      }
      visiting.remove(table);
      depths[table] = depth;
      return depth;
    }

    for (final table in tables) {
      depthOf(table.name);
    }
    return depths;
  }

  static List<PlacedTable> _place(
    List<DbTableNode> tables,
    Map<String, int> depths,
    String? group,
  ) {
    final columns = <int, List<DbTableNode>>{};
    for (final table in tables) {
      columns.putIfAbsent(depths[table.name] ?? 0, () => []).add(table);
    }

    // 같은 칸 안에서는 분류끼리 붙여 둡니다. 이름순으로만 두면 관련 없는 상자가
    // 사이에 끼어 선이 그 위를 지나갑니다.
    for (final column in columns.values) {
      column.sort((a, b) {
        final byGroup = a.group.compareTo(b.group);
        return byGroup != 0 ? byGroup : a.name.compareTo(b.name);
      });
    }

    final heights = {
      for (final entry in columns.entries)
        entry.key: entry.value.fold<double>(
          0,
          (sum, table) => sum + nodeHeight(table) + rowGap,
        ),
    };
    final tallest = heights.values.fold<double>(0, (a, b) => a > b ? a : b);

    final placed = <PlacedTable>[];
    for (final entry in columns.entries) {
      final depth = entry.key;
      // 칸마다 세로 가운데를 맞춥니다. 위로 몰아 두면 짧은 칸의 선이 길게 늘어집니다.
      var y = canvasPadding + (tallest - heights[depth]!) / 2;
      for (final table in entry.value) {
        final height = nodeHeight(table);
        final keys = table.keyColumns.take(maxKeyRows).toList();
        placed.add(
          PlacedTable(
            node: table,
            rect: Rect.fromLTWH(
              canvasPadding + depth * (nodeWidth + columnGap),
              y,
              nodeWidth,
              height,
            ),
            depth: depth,
            dimmed: group != null && table.group != group,
            visibleKeyColumns: keys,
            hiddenKeyCount: table.keyColumns.length - keys.length,
          ),
        );
        y += height + rowGap;
      }
    }
    return placed;
  }

  static double nodeHeight(DbTableNode table) {
    final rows = table.keyColumns.length > maxKeyRows
        ? maxKeyRows + 1 // 접은 개수를 적는 줄
        : table.keyColumns.length;
    return headerHeight +
        rows * keyRowHeight +
        nodePaddingBottom +
        borderWidth * 2;
  }

  /// 선이 상자의 어느 면 어디에 붙을지 정합니다.
  ///
  /// 가까운 면끼리 이어야 선이 상자를 가로지르지 않습니다. 그리고 **한 면에 여러
  /// 선이 붙으면 세로로 나눠 답니다.** `parents` 는 일곱 군데에서 가리켜지는데,
  /// 전부 면 한가운데에 모으면 끝 표시가 겹쳐 몇 개인지도 보이지 않습니다.
  static List<PlacedRelation> _connectAll(
    List<DbRelation> relations,
    Map<String, PlacedTable> byName,
  ) {
    final anchors = <_Anchor>[];
    for (final relation in relations) {
      final from = byName[relation.fromTable];
      final to = byName[relation.toTable];
      if (from == null || to == null) continue;

      final fromOnLeft = from.rect.center.dx > to.rect.center.dx;
      anchors.add(
        _Anchor(
          relation: relation,
          from: from,
          to: to,
          fromOnLeft: fromOnLeft,
        ),
      );
    }

    // (테이블, 면) 별로 모아 붙는 자리를 나눕니다. 상대 쪽이 위에 있는 선을 위에
    // 붙여야 선끼리 서로 넘어가지 않습니다.
    final bySide = <String, List<_Anchor>>{};
    for (final anchor in anchors) {
      bySide.putIfAbsent(anchor.startKey, () => []).add(anchor);
      bySide.putIfAbsent(anchor.endKey, () => []).add(anchor);
    }

    final startY = <_Anchor, double>{};
    final endY = <_Anchor, double>{};
    for (final entry in bySide.entries) {
      final side = entry.value;
      // 한 무리는 모두 같은 상자의 같은 면입니다. 나가는 선과 들어오는 선이
      // 섞여 있어도 붙는 면은 하나이므로 아무 선에서나 상자를 꺼내면 됩니다.
      final box = side.first.startKey == entry.key
          ? side.first.from
          : side.first.to;

      side.sort((a, b) {
        final aOther = a.startKey == entry.key ? a.to : a.from;
        final bOther = b.startKey == entry.key ? b.to : b.from;
        return aOther.rect.center.dy.compareTo(bOther.rect.center.dy);
      });

      for (var i = 0; i < side.length; i++) {
        final anchor = side[i];
        final y = _spread(box, i, side.length);
        if (anchor.startKey == entry.key) {
          startY[anchor] = y;
        } else {
          endY[anchor] = y;
        }
      }
    }

    return [
      for (final anchor in anchors)
        PlacedRelation(
          relation: anchor.relation,
          start: Offset(
            anchor.fromOnLeft ? anchor.from.rect.left : anchor.from.rect.right,
            startY[anchor] ?? anchor.from.rect.center.dy,
          ),
          end: Offset(
            anchor.fromOnLeft ? anchor.to.rect.right : anchor.to.rect.left,
            endY[anchor] ?? anchor.to.rect.center.dy,
          ),
          startsOnLeft: anchor.fromOnLeft,
          endsOnLeft: !anchor.fromOnLeft,
        ),
    ];
  }

  /// 상자 한 면을 [count] 등분해 [index] 번째 자리를 돌려줍니다.
  ///
  /// 머리 부분은 피합니다. 거기 붙으면 선이 제목 글자를 가립니다.
  static double _spread(PlacedTable box, int index, int count) {
    if (count <= 1) return box.rect.center.dy;
    final top = box.rect.top + headerHeight / 2;
    final bottom = box.rect.bottom - nodePaddingBottom;
    return top + (bottom - top) * (index + 0.5) / count;
  }

  static Size _canvasSize(List<PlacedTable> tables) {
    var right = 0.0;
    var bottom = 0.0;
    for (final table in tables) {
      if (table.rect.right > right) right = table.rect.right;
      if (table.rect.bottom > bottom) bottom = table.rect.bottom;
    }
    return Size(right + canvasPadding, bottom + canvasPadding);
  }
}

/// 선 하나가 어느 상자의 어느 면에 붙는지. 자리를 나누는 동안만 씁니다.
class _Anchor {
  _Anchor({
    required this.relation,
    required this.from,
    required this.to,
    required this.fromOnLeft,
  });

  final DbRelation relation;
  final PlacedTable from;
  final PlacedTable to;
  final bool fromOnLeft;

  String get startKey => '${from.name}:${fromOnLeft ? 'L' : 'R'}';

  String get endKey => '${to.name}:${fromOnLeft ? 'R' : 'L'}';
}

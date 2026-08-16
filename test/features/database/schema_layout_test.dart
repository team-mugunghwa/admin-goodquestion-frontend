import 'package:flutter_test/flutter_test.dart';
import 'package:goodquestion_admin/features/database/domain/entities/db_schema.dart';
import 'package:goodquestion_admin/features/database/presentation/diagram/schema_layout.dart';

DbTableNode _node(String name, {String group = '사용자'}) => DbTableNode(
  name: name,
  comment: '$name 설명',
  group: group,
  columnCount: 5,
  containsPersonalData: false,
  keyColumns: const [
    DbKeyColumn(name: 'id', primaryKey: true, foreignKey: false),
  ],
);

DbRelation _relation(String from, String to, {bool optional = false}) =>
    DbRelation(
      fromTable: from,
      fromColumn: '${to}_id',
      toTable: to,
      toColumn: 'id',
      optional: optional,
    );

int _depthOf(DiagramLayout layout, String name) =>
    layout.tables.firstWhere((table) => table.name == name).depth;

void main() {
  test('가리켜지는 테이블이 가리키는 테이블보다 왼쪽에 놓인다', () {
    final layout = SchemaLayout.compute(
      DbSchemaGraph(
        tables: [_node('parents'), _node('children'), _node('word_practices')],
        relations: [
          _relation('children', 'parents'),
          _relation('word_practices', 'children'),
        ],
      ),
    );

    expect(_depthOf(layout, 'parents'), 0);
    expect(_depthOf(layout, 'children'), 1);
    expect(_depthOf(layout, 'word_practices'), 2);

    // 깊이가 곧 가로 위치다. 이것이 어긋나면 선이 뒤로 흐른다.
    final parents = layout.tables.firstWhere((t) => t.name == 'parents');
    final children = layout.tables.firstWhere((t) => t.name == 'children');
    expect(parents.rect.left, lessThan(children.rect.left));
  });

  test('참조가 서로 물려 있어도 배치가 끝난다', () {
    // 실제 스키마에 순환 참조가 생길 수 있다. 여기서 멈추면 화면이 영영 안 뜬다.
    final layout = SchemaLayout.compute(
      DbSchemaGraph(
        tables: [_node('a'), _node('b')],
        relations: [_relation('a', 'b'), _relation('b', 'a')],
      ),
    );

    expect(layout.tables, hasLength(2));
    expect(layout.relations, hasLength(2));
  });

  test('자기를 가리키는 관계는 선으로 그리지 않는다', () {
    final layout = SchemaLayout.compute(
      DbSchemaGraph(
        tables: [_node('categories')],
        relations: [_relation('categories', 'categories')],
      ),
    );

    // 상자 하나 안에서 끝나는 관계라 배치에 쓸 두 점이 없다.
    expect(layout.tables, hasLength(1));
    expect(layout.relations, isEmpty);
  });

  test('분류를 고르면 맞닿은 테이블까지 흐리게 함께 나온다', () {
    final graph = DbSchemaGraph(
      tables: [
        _node('parents'),
        _node('children'),
        _node('story_sessions', group: '진행 기록'),
        _node('topics', group: '콘텐츠'),
      ],
      relations: [
        _relation('children', 'parents'),
        _relation('story_sessions', 'children'),
      ],
    );

    final layout = SchemaLayout.compute(graph, group: '진행 기록');
    final names = layout.tables.map((table) => table.name).toList();

    // 고른 분류만 남기면 그 기록이 어느 아이의 것인지 안 보인다.
    expect(names, containsAll(['story_sessions', 'children']));
    expect(names, isNot(contains('topics')));

    expect(
      layout.tables.firstWhere((t) => t.name == 'story_sessions').dimmed,
      isFalse,
    );
    expect(
      layout.tables.firstWhere((t) => t.name == 'children').dimmed,
      isTrue,
    );
  });

  test('상자가 겹치지 않는다', () {
    final tables = [for (var i = 0; i < 12; i++) _node('table_$i')];
    final layout = SchemaLayout.compute(
      DbSchemaGraph(
        tables: tables,
        relations: [
          for (var i = 1; i < 12; i++) _relation('table_$i', 'table_0'),
        ],
      ),
    );

    for (final a in layout.tables) {
      for (final b in layout.tables) {
        if (a.name == b.name) continue;
        expect(
          a.rect.overlaps(b.rect),
          isFalse,
          reason: '${a.name} 과 ${b.name} 이 겹칩니다',
        );
      }
    }
  });

  test('선은 상자의 마주 보는 면에 붙는다', () {
    final layout = SchemaLayout.compute(
      DbSchemaGraph(
        tables: [_node('parents'), _node('children')],
        relations: [_relation('children', 'parents')],
      ),
    );

    final edge = layout.relations.single;
    final parents = layout.tables.firstWhere((t) => t.name == 'parents');
    final children = layout.tables.firstWhere((t) => t.name == 'children');

    // 가리키는 쪽이 오른쪽에 있으니 그 왼쪽 면에서 나가 부모의 오른쪽 면에 닿아야 한다.
    expect(edge.start.dx, children.rect.left);
    expect(edge.end.dx, parents.rect.right);
    expect(edge.startsOnLeft, isTrue);
    expect(edge.endsOnLeft, isFalse);
  });

  test('캔버스는 모든 상자를 담는다', () {
    final layout = SchemaLayout.compute(
      DbSchemaGraph(
        tables: [_node('a'), _node('b'), _node('c')],
        relations: [_relation('b', 'a'), _relation('c', 'b')],
      ),
    );

    for (final table in layout.tables) {
      expect(table.rect.right, lessThanOrEqualTo(layout.size.width));
      expect(table.rect.bottom, lessThanOrEqualTo(layout.size.height));
    }
  });

  test('키가 많으면 접고 개수를 알린다', () {
    final busy = DbTableNode(
      name: 'story_scenes',
      group: '콘텐츠',
      columnCount: 20,
      containsPersonalData: false,
      keyColumns: [
        for (var i = 0; i < 10; i++)
          DbKeyColumn(name: 'col_$i', primaryKey: i == 0, foreignKey: i > 0),
      ],
    );

    final layout = SchemaLayout.compute(
      DbSchemaGraph(tables: [busy], relations: const []),
    );
    final placed = layout.tables.single;

    expect(placed.visibleKeyColumns, hasLength(SchemaLayout.maxKeyRows));
    expect(placed.hiddenKeyCount, 10 - SchemaLayout.maxKeyRows);
  });

  test('빈 스키마는 빈 배치를 준다', () {
    expect(
      SchemaLayout.compute(const DbSchemaGraph.empty()).isEmpty,
      isTrue,
    );
    // 없는 분류를 고른 경우도 같다.
    expect(
      SchemaLayout.compute(
        DbSchemaGraph(tables: [_node('parents')], relations: const []),
        group: '없는 분류',
      ).isEmpty,
      isTrue,
    );
  });

  test('한 면에 여러 선이 붙으면 자리를 나눠 답니다', () {
    // parents 는 여러 곳에서 가리켜집니다. 전부 면 한가운데에 모으면 끝 표시가
    // 겹쳐서 몇 개가 붙었는지 보이지 않습니다.
    final layout = SchemaLayout.compute(
      DbSchemaGraph(
        tables: [
          _node('parents'),
          _node('children'),
          _node('inquiries'),
          _node('device_tokens'),
        ],
        relations: [
          _relation('children', 'parents'),
          _relation('inquiries', 'parents'),
          _relation('device_tokens', 'parents'),
        ],
      ),
    );

    final endpoints = layout.relations.map((edge) => edge.end.dy).toList();
    expect(endpoints.toSet(), hasLength(3));

    // 그래도 모두 상자 안에 붙어야 합니다.
    final parents = layout.tables.firstWhere((t) => t.name == 'parents');
    for (final y in endpoints) {
      expect(y, greaterThanOrEqualTo(parents.rect.top));
      expect(y, lessThanOrEqualTo(parents.rect.bottom));
    }
  });

  test('선이 하나뿐이면 면 한가운데에 붙는다', () {
    final layout = SchemaLayout.compute(
      DbSchemaGraph(
        tables: [_node('parents'), _node('children')],
        relations: [_relation('children', 'parents')],
      ),
    );

    final parents = layout.tables.firstWhere((t) => t.name == 'parents');
    expect(layout.relations.single.end.dy, parents.rect.center.dy);
  });

  test('상자 높이에 테두리가 들어가 있다', () {
    // 빼먹으면 안쪽 내용이 넘쳐 마지막 키 줄이 잘립니다.
    final table = _node('parents');
    expect(
      SchemaLayout.nodeHeight(table),
      SchemaLayout.headerHeight +
          table.keyColumns.length * SchemaLayout.keyRowHeight +
          SchemaLayout.nodePaddingBottom +
          SchemaLayout.borderWidth * 2,
    );
  });

  test('숨기기를 켜면 관계 없는 테이블이 빠지고 개수가 남는다', () {
    final layout = SchemaLayout.compute(
      DbSchemaGraph(
        tables: [
          _node('parents'),
          _node('children'),
          // 마이그레이션 이력처럼 어디와도 이어지지 않는 테이블들.
          _node('flyway_schema_history', group: '시스템'),
          _node('guides', group: '콘텐츠'),
        ],
        relations: [_relation('children', 'parents')],
      ),
      hideIsolated: true,
    );

    expect(layout.tables.map((t) => t.name), ['parents', 'children']);
    expect(layout.hiddenIsolatedCount, 2);
  });

  test('자기 자신만 가리키는 테이블도 숨긴다', () {
    // 관계 목록에는 있지만 선은 그려지지 않아서, 남겨 두면 여전히 외딴 상자다.
    final layout = SchemaLayout.compute(
      DbSchemaGraph(
        tables: [_node('parents'), _node('children'), _node('categories')],
        relations: [
          _relation('children', 'parents'),
          _relation('categories', 'categories'),
        ],
      ),
      hideIsolated: true,
    );

    expect(layout.tables.map((t) => t.name), isNot(contains('categories')));
    expect(layout.hiddenIsolatedCount, 1);
  });

  test('숨기기를 꺼 두면 지금까지와 같다', () {
    final graph = DbSchemaGraph(
      tables: [_node('parents'), _node('flyway_schema_history', group: '시스템')],
      relations: const [],
    );

    final layout = SchemaLayout.compute(graph);
    expect(layout.tables, hasLength(2));
    expect(layout.hiddenIsolatedCount, 0);
  });

  test('분류를 고른 상태에서도 숨기기가 함께 동작한다', () {
    final layout = SchemaLayout.compute(
      DbSchemaGraph(
        tables: [
          _node('parents'),
          _node('children'),
          _node('story_sessions', group: '진행 기록'),
          // 같은 분류지만 관계가 없는 테이블.
          _node('word_practices', group: '진행 기록'),
        ],
        relations: [
          _relation('children', 'parents'),
          _relation('story_sessions', 'children'),
        ],
      ),
      group: '진행 기록',
      hideIsolated: true,
    );

    final names = layout.tables.map((t) => t.name).toList();
    expect(names, containsAll(['story_sessions', 'children']));
    expect(names, isNot(contains('word_practices')));
    expect(layout.hiddenIsolatedCount, 1);
  });

  test('전부 숨겨져도 숨긴 개수는 알려 준다', () {
    // 빈 화면만 남으면 고장으로 보인다.
    final layout = SchemaLayout.compute(
      DbSchemaGraph(
        tables: [_node('a'), _node('b')],
        relations: const [],
      ),
      hideIsolated: true,
    );

    expect(layout.isEmpty, isTrue);
    expect(layout.hiddenIsolatedCount, 2);
  });
}

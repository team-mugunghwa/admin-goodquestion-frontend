import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goodquestion_admin/core/di/injector.dart';
import 'package:goodquestion_admin/features/database/domain/entities/db_schema.dart';
import 'package:goodquestion_admin/features/database/domain/repositories/database_repository.dart';
import 'package:goodquestion_admin/features/database/domain/usecases/database_use_cases.dart';
import 'package:goodquestion_admin/features/database/presentation/views/schema_diagram_view.dart';
import 'package:mocktail/mocktail.dart';

class _MockDatabaseRepository extends Mock implements DatabaseRepository {}

/// 화면보다 확실히 큰 관계도.
DbSchemaGraph _wideGraph() {
  final tables = <DbTableNode>[
    for (var i = 0; i < 8; i++)
      DbTableNode(
        name: 'table_$i',
        comment: '$i번 테이블',
        group: '사용자',
        columnCount: 4,
        containsPersonalData: false,
        keyColumns: const [
          DbKeyColumn(name: 'id', primaryKey: true, foreignKey: false),
        ],
      ),
  ];
  tables.add(
    const DbTableNode(
      name: 'flyway_schema_history',
      comment: '마이그레이션 이력',
      group: '시스템',
      columnCount: 4,
      containsPersonalData: false,
      keyColumns: [
        DbKeyColumn(name: 'installed_rank', primaryKey: true, foreignKey: false),
      ],
    ),
  );
  return DbSchemaGraph(
    tables: tables,
    relations: [
      // 한 줄로 길게 이어 붙여 가로로 넓은 관계도를 만듭니다.
      for (var i = 1; i < 8; i++)
        DbRelation(
          fromTable: 'table_$i',
          fromColumn: 'prev_id',
          toTable: 'table_${i - 1}',
          toColumn: 'id',
          optional: false,
        ),
    ],
  );
}

double _scaleOf(WidgetTester tester) {
  final viewer = tester.widget<InteractiveViewer>(
    find.byType(InteractiveViewer),
  );
  return viewer.transformationController!.value.getMaxScaleOnAxis();
}

void main() {
  setUp(() {
    final graph = _wideGraph();
    final repository = _MockDatabaseRepository();
    when(repository.getRelations).thenAnswer((_) async => graph);
    getIt.registerLazySingleton(() => GetRelationsUseCase(repository));
  });

  tearDown(getIt.reset);

  Future<void> pumpDiagram(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1000, 700);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: SchemaDiagramView())),
    );
    await tester.pumpAndSettle();
  }

  // 100% 로만 두면 39개 테이블에서는 왼쪽 위 구석만 보입니다. 처음 열었을 때
  // 필요한 것은 "전체가 어떻게 생겼는가"입니다.
  testWidgets('열면 관계도 전체가 보이도록 줄여서 보여 준다', (tester) async {
    await pumpDiagram(tester);

    expect(_scaleOf(tester), lessThan(1));
    expect(_scaleOf(tester), greaterThan(0));
  });

  testWidgets('상자를 눌러도 보던 배율이 그대로다', (tester) async {
    await pumpDiagram(tester);
    final before = _scaleOf(tester);

    // 누르면 아래에 설명 칸이 생기면서 캔버스가 낮아집니다. 그때 다시 맞추면
    // 상자 하나 눌렀을 뿐인데 관계도가 확대/축소되어 보던 자리를 잃습니다.
    await tester.tap(find.text('0번 테이블'));
    await tester.pumpAndSettle();

    expect(find.textContaining('table_0'), findsWidgets);
    expect(_scaleOf(tester), before);
  });

  testWidgets('숨기기 토글을 누르면 관계 없는 상자가 사라진다', (tester) async {
    await pumpDiagram(tester);

    // 고립 테이블까지 전부 보이는 상태에서 시작한다.
    expect(find.text('마이그레이션 이력'), findsOneWidget);

    await tester.tap(find.text('관계 없는 테이블 숨기기'));
    await tester.pumpAndSettle();

    expect(find.text('마이그레이션 이력'), findsNothing);
    // 몇 개를 숨겼는지도 보여야 한다. 말없이 빼면 화면을 의심하게 된다.
    expect(find.textContaining('1개를 숨겼습니다'), findsOneWidget);

    // 다시 누르면 돌아온다.
    await tester.tap(find.text('관계 없는 테이블 숨기기'));
    await tester.pumpAndSettle();
    expect(find.text('마이그레이션 이력'), findsOneWidget);
  });

  testWidgets('전부 숨겨져도 필터 바가 남아 되돌릴 수 있다', (tester) async {
    await pumpDiagram(tester);

    // 고립 테이블만 있는 분류로 좁힌 뒤 숨기면 화면에 남는 상자가 없다.
    await tester.tap(find.text('시스템'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('관계 없는 테이블 숨기기'));
    await tester.pumpAndSettle();

    expect(find.textContaining('보여 줄 테이블이 없습니다'), findsOneWidget);

    // 여기서 토글이 사라지면 되돌릴 방법이 없다. 실제로 그런 함정이 있었다.
    await tester.tap(find.text('관계 없는 테이블 숨기기'));
    await tester.pumpAndSettle();
    expect(find.text('마이그레이션 이력'), findsOneWidget);
  });
}

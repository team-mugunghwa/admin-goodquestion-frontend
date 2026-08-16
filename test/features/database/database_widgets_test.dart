import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goodquestion_admin/features/database/domain/entities/db_schema.dart';
import 'package:goodquestion_admin/features/database/domain/repositories/database_repository.dart';
import 'package:goodquestion_admin/features/database/domain/usecases/database_use_cases.dart';
import 'package:goodquestion_admin/features/database/presentation/viewmodels/table_detail_view_model.dart';
import 'package:goodquestion_admin/features/database/presentation/widgets/column_list.dart';
import 'package:goodquestion_admin/features/database/presentation/widgets/row_grid.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

class _MockDatabaseRepository extends Mock implements DatabaseRepository {}

const _columns = [
  DbColumn(
    position: 1,
    name: 'id',
    type: 'uuid',
    nullable: false,
    primaryKey: true,
    masked: false,
    comment: '아이 식별자',
  ),
  DbColumn(
    position: 2,
    name: 'parent_id',
    type: 'uuid',
    nullable: false,
    primaryKey: false,
    masked: false,
    comment: '보호자',
    referencesTable: 'parents',
    referencesColumn: 'id',
  ),
  DbColumn(
    position: 3,
    name: 'name',
    type: 'varchar(30)',
    nullable: true,
    primaryKey: false,
    masked: false,
    comment: '아이 이름',
  ),
];

const _detail = DbTableDetail(
  name: 'children',
  comment: '아이 프로필',
  group: '사용자',
  rowCount: 2,
  containsPersonalData: true,
  columns: _columns,
  indexes: [
    DbIndex(
      name: 'children_pkey',
      definition: 'CREATE UNIQUE INDEX children_pkey ON public.children (id)',
      unique: true,
      primaryKey: true,
    ),
  ],
);

const _rows = DbRowPage(
  columns: _columns,
  rows: [
    {'id': 'a1', 'parent_id': 'p1', 'name': '지우'},
    {'id': 'a2', 'parent_id': 'p1', 'name': null},
  ],
  page: 0,
  size: 50,
  totalElements: 2,
  totalPages: 1,
);

void main() {
  Widget wrap(Widget child) => MaterialApp(
    home: Scaffold(
      body: SizedBox(width: 1000, height: 600, child: child),
    ),
  );

  testWidgets('컬럼 목록은 설명과 참조 테이블을 보여준다', (tester) async {
    await tester.pumpWidget(
      wrap(const SingleChildScrollView(child: ColumnList(detail: _detail))),
    );

    expect(find.text('아이 이름'), findsOneWidget);
    expect(find.text('parents.id 을(를) 가리킵니다'), findsOneWidget);
    // 기본키는 배지로도 알린다.
    expect(find.text('PK'), findsOneWidget);
    expect(find.text('기본키'), findsOneWidget);
    // 필수 여부는 색이 아니라 글자로 구분한다.
    expect(find.text('선택'), findsOneWidget);
  });

  // 이 검사가 있는 이유: AppCard 안에서는 Expanded 가 통하지 않아 표가 통째로
  // 그려지지 않은 적이 있습니다. 릴리스 빌드에서는 오류도 뜨지 않아 화면이 그냥
  // 비어 보였습니다.
  testWidgets('값 표는 행과 페이지 정보를 실제로 그린다', (tester) async {
    final repository = _MockDatabaseRepository();
    when(() => repository.getTable(any())).thenAnswer((_) async => _detail);
    when(
      () => repository.getRows(
        tableName: any(named: 'tableName'),
        page: any(named: 'page'),
        size: any(named: 'size'),
        sortColumn: any(named: 'sortColumn'),
        sortDirection: any(named: 'sortDirection'),
        filterColumn: any(named: 'filterColumn'),
        keyword: any(named: 'keyword'),
      ),
    ).thenAnswer((_) async => _rows);

    final viewModel = TableDetailViewModel(
      getTable: GetTableUseCase(repository),
      getRows: GetTableRowsUseCase(repository),
      tableName: 'children',
    );
    await viewModel.load();

    await tester.pumpWidget(
      wrap(
        ChangeNotifierProvider.value(value: viewModel, child: const RowGrid()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('지우'), findsOneWidget);
    // 빈 값은 지운 것과 구분되도록 null 로 적는다.
    expect(find.text('null'), findsOneWidget);
    expect(find.textContaining('전체 2행'), findsOneWidget);
    expect(find.text('1 / 1'), findsOneWidget);
  });

  testWidgets('열 머리를 누르면 그 컬럼으로 정렬한다', (tester) async {
    final repository = _MockDatabaseRepository();
    when(() => repository.getTable(any())).thenAnswer((_) async => _detail);
    when(
      () => repository.getRows(
        tableName: any(named: 'tableName'),
        page: any(named: 'page'),
        size: any(named: 'size'),
        sortColumn: any(named: 'sortColumn'),
        sortDirection: any(named: 'sortDirection'),
        filterColumn: any(named: 'filterColumn'),
        keyword: any(named: 'keyword'),
      ),
    ).thenAnswer((_) async => _rows);

    final viewModel = TableDetailViewModel(
      getTable: GetTableUseCase(repository),
      getRows: GetTableRowsUseCase(repository),
      tableName: 'children',
    );
    await viewModel.load();

    await tester.pumpWidget(
      wrap(
        ChangeNotifierProvider.value(value: viewModel, child: const RowGrid()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(InkWell, 'name').first);
    await tester.pumpAndSettle();

    expect(viewModel.sortColumn, 'name');
    expect(viewModel.sortDirection, 'asc');
  });
}

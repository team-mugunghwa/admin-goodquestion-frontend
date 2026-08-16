import 'package:flutter_test/flutter_test.dart';
import 'package:goodquestion_admin/core/error/failure.dart';
import 'package:goodquestion_admin/core/state/view_state.dart';
import 'package:goodquestion_admin/features/database/domain/entities/db_schema.dart';
import 'package:goodquestion_admin/features/database/domain/repositories/database_repository.dart';
import 'package:goodquestion_admin/features/database/domain/usecases/database_use_cases.dart';
import 'package:goodquestion_admin/features/database/presentation/viewmodels/table_detail_view_model.dart';
import 'package:mocktail/mocktail.dart';

class _MockDatabaseRepository extends Mock implements DatabaseRepository {}

const _detail = DbTableDetail(
  name: 'children',
  comment: '아이 프로필',
  group: '사용자',
  rowCount: 3,
  containsPersonalData: true,
  columns: [
    DbColumn(
      position: 1,
      name: 'id',
      type: 'uuid',
      nullable: false,
      primaryKey: true,
      masked: false,
    ),
    DbColumn(
      position: 2,
      name: 'nickname',
      type: 'varchar(30)',
      nullable: false,
      primaryKey: false,
      masked: false,
      comment: '아이가 앱에서 보는 이름',
    ),
  ],
  indexes: [],
);

DbRowPage _page({int page = 0, int totalPages = 3}) => DbRowPage(
  columns: _detail.columns,
  rows: const [
    {'id': 'a', 'nickname': '봄이'},
  ],
  page: page,
  size: 50,
  totalElements: 120,
  totalPages: totalPages,
);

void main() {
  late _MockDatabaseRepository repository;
  late TableDetailViewModel viewModel;

  void stubRows() {
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
    ).thenAnswer((_) async => _page());
  }

  setUp(() {
    repository = _MockDatabaseRepository();
    viewModel = TableDetailViewModel(
      getTable: GetTableUseCase(repository),
      getRows: GetTableRowsUseCase(repository),
      tableName: 'children',
    );
  });

  test('불러오면 구조와 값이 함께 채워진다', () async {
    when(() => repository.getTable('children')).thenAnswer((_) async => _detail);
    stubRows();

    await viewModel.load();

    expect(viewModel.state, ViewState.success);
    expect(viewModel.detail?.columns, hasLength(2));
    expect(viewModel.rows.rows, hasLength(1));
  });

  test('검색 조건을 바꾸면 첫 페이지부터 다시 부른다', () async {
    when(() => repository.getTable('children')).thenAnswer((_) async => _detail);
    stubRows();

    await viewModel.load();
    await viewModel.loadRows(page: 2);
    await viewModel.search(column: 'nickname', keyword: '  봄이  ');

    expect(viewModel.keyword, '봄이');
    verify(
      () => repository.getRows(
        tableName: 'children',
        page: 0,
        size: TableDetailViewModel.pageSize,
        sortColumn: null,
        sortDirection: 'desc',
        filterColumn: 'nickname',
        keyword: '봄이',
      ),
    ).called(1);
  });

  test('같은 컬럼을 다시 누르면 정렬 방향만 뒤집힌다', () async {
    when(() => repository.getTable('children')).thenAnswer((_) async => _detail);
    stubRows();

    await viewModel.load();

    await viewModel.sortBy('nickname');
    expect(viewModel.sortColumn, 'nickname');
    expect(viewModel.sortDirection, 'asc');

    await viewModel.sortBy('nickname');
    expect(viewModel.sortDirection, 'desc');

    // 다른 컬럼으로 옮기면 오름차순에서 다시 시작한다.
    await viewModel.sortBy('id');
    expect(viewModel.sortColumn, 'id');
    expect(viewModel.sortDirection, 'asc');
  });

  test('페이지를 넘기다 실패해도 보고 있던 표는 남는다', () async {
    when(() => repository.getTable('children')).thenAnswer((_) async => _detail);
    stubRows();

    await viewModel.load();

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
    ).thenThrow(
      const ServerFailure(message: '값을 불러오지 못했습니다.', code: 'INTERNAL_ERROR'),
    );

    await viewModel.loadRows(page: 1);

    expect(viewModel.state, ViewState.success);
    expect(viewModel.errorMessage, '값을 불러오지 못했습니다.');
    expect(viewModel.rows.rows, hasLength(1));
  });

  test('구조를 불러오지 못하면 오류 상태가 된다', () async {
    when(() => repository.getTable('children')).thenThrow(
      const ServerFailure(message: '없는 테이블입니다.', code: 'NOT_FOUND'),
    );
    stubRows();

    await viewModel.load();

    expect(viewModel.state, ViewState.error);
    expect(viewModel.errorMessage, '없는 테이블입니다.');
  });
}

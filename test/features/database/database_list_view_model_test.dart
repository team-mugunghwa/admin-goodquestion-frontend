import 'package:flutter_test/flutter_test.dart';
import 'package:goodquestion_admin/core/error/failure.dart';
import 'package:goodquestion_admin/core/state/view_state.dart';
import 'package:goodquestion_admin/features/database/domain/entities/db_schema.dart';
import 'package:goodquestion_admin/features/database/domain/repositories/database_repository.dart';
import 'package:goodquestion_admin/features/database/domain/usecases/database_use_cases.dart';
import 'package:goodquestion_admin/features/database/presentation/viewmodels/database_list_view_model.dart';
import 'package:mocktail/mocktail.dart';

class _MockDatabaseRepository extends Mock implements DatabaseRepository {}

DbTableSummary _table(
  String name, {
  String? comment,
  String group = '사용자',
  bool personal = false,
}) => DbTableSummary(
  name: name,
  comment: comment,
  group: group,
  columnCount: 5,
  containsPersonalData: personal,
);

void main() {
  late _MockDatabaseRepository repository;
  late DatabaseListViewModel viewModel;

  setUp(() {
    repository = _MockDatabaseRepository();
    viewModel = DatabaseListViewModel(GetTablesUseCase(repository));
  });

  test('불러오면 성공 상태가 되고 목록이 채워진다', () async {
    when(() => repository.getTables()).thenAnswer(
      (_) async => [_table('parents'), _table('children')],
    );

    await viewModel.load();

    expect(viewModel.state, ViewState.success);
    expect(viewModel.tables, hasLength(2));
    expect(viewModel.totalCount, 2);
  });

  test('설명으로도 검색된다', () async {
    when(() => repository.getTables()).thenAnswer(
      (_) async => [
        _table('stardust_wallets', comment: '아이별 별가루 지갑', group: '보상'),
        _table('parents', comment: '보호자 계정'),
      ],
    );

    await viewModel.load();
    // 찾는 사람은 테이블 이름을 모릅니다. 뜻으로 찾을 수 있어야 합니다.
    viewModel.search('별가루');

    expect(viewModel.tables, hasLength(1));
    expect(viewModel.tables.single.name, 'stardust_wallets');
    // 걸러도 전체 개수는 그대로여서 "2개 중 1개"를 보여줄 수 있다.
    expect(viewModel.totalCount, 2);
  });

  test('검색은 서버를 다시 부르지 않는다', () async {
    when(() => repository.getTables()).thenAnswer((_) async => [_table('parents')]);

    await viewModel.load();
    viewModel.search('보호자');
    viewModel.search('보');

    verify(() => repository.getTables()).called(1);
  });

  test('분류별로 묶이고 걸러진 결과만 들어간다', () async {
    when(() => repository.getTables()).thenAnswer(
      (_) async => [
        _table('parents', comment: '보호자 계정'),
        _table('children', comment: '아이 프로필'),
        _table('topics', comment: '이야기 주제', group: '콘텐츠'),
      ],
    );

    await viewModel.load();

    expect(viewModel.grouped.keys, ['사용자', '콘텐츠']);
    expect(viewModel.grouped['사용자'], hasLength(2));

    viewModel.search('콘텐츠');
    expect(viewModel.grouped.keys, ['콘텐츠']);
  });

  test('불러오기에 실패하면 오류 상태와 메시지가 남는다', () async {
    when(() => repository.getTables()).thenThrow(
      const ServerFailure(message: '목록을 불러오지 못했습니다.', code: 'INTERNAL_ERROR'),
    );

    await viewModel.load();

    expect(viewModel.state, ViewState.error);
    expect(viewModel.errorMessage, '목록을 불러오지 못했습니다.');
  });
}

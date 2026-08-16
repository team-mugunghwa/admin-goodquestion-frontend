import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:goodquestion_admin/core/error/failure.dart';
import 'package:goodquestion_admin/core/network/page_result.dart';
import 'package:goodquestion_admin/core/state/view_state.dart';
import 'package:goodquestion_admin/features/audit/domain/audit_log.dart';
import 'package:goodquestion_admin/features/audit/presentation/viewmodels/audit_log_view_model.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuditLogRepository extends Mock implements AuditLogRepository {}

/// mocktail 의 any(named:) 가 쓸 기본값.
class _FakeFilter extends Fake implements AuditLogFilter {}

AuditLog _log(String id) => AuditLog(
  id: id,
  adminEmail: 'admin@goodquestion.kr',
  action: 'DELETE',
  targetType: 'NOTICE',
);

PageResult<AuditLog> _page(List<AuditLog> logs) => PageResult(
  content: logs,
  page: 0,
  size: 20,
  totalElements: logs.length,
  totalPages: 1,
);

void main() {
  setUpAll(() => registerFallbackValue(_FakeFilter()));

  late _MockAuditLogRepository repository;
  late List<(String, List<int>, String)> saved;
  late AuditLogViewModel viewModel;

  setUp(() {
    repository = _MockAuditLogRepository();
    saved = [];
    viewModel = AuditLogViewModel(
      repository,
      saveFile: (name, bytes, mime) => saved.add((name, bytes, mime)),
    );
  });

  void stubLogs() {
    when(
      () => repository.getLogs(
        filter: any(named: 'filter'),
        page: any(named: 'page'),
        size: any(named: 'size'),
      ),
    ).thenAnswer((_) async => _page([_log('1')]));
  }

  test('필터를 바꾸면 첫 페이지부터 다시 불러온다', () async {
    stubLogs();

    await viewModel.load(page: 3);
    await viewModel.changeAction('READ_DATA');

    final captured = verify(
      () => repository.getLogs(
        filter: captureAny(named: 'filter'),
        page: captureAny(named: 'page'),
        size: any(named: 'size'),
      ),
    ).captured;
    // 마지막 호출이 바뀐 필터와 0페이지여야 한다.
    expect((captured[captured.length - 2] as AuditLogFilter).action, 'READ_DATA');
    expect(captured.last, 0);
  });

  test('이메일 검색어의 양쪽 공백은 지우고, 빈 값은 필터 해제다', () async {
    stubLogs();

    await viewModel.changeAdminEmail('  admin  ');
    expect(viewModel.filter.adminEmail, 'admin');

    await viewModel.changeAdminEmail('   ');
    expect(viewModel.filter.adminEmail, isNull);
  });

  test('내보내기는 지금 필터 그대로 CSV 를 받아 저장한다', () async {
    stubLogs();
    when(() => repository.exportCsv(any())).thenAnswer(
      (_) async => AuditLogCsv(
        fileName: 'audit_logs_20260816.csv',
        bytes: Uint8List.fromList([1, 2, 3]),
      ),
    );

    await viewModel.changeAction('DELETE');
    final ok = await viewModel.export();

    expect(ok, isTrue);
    expect(saved.single.$1, 'audit_logs_20260816.csv');
    expect(saved.single.$3, 'text/csv');
    final filter =
        verify(() => repository.exportCsv(captureAny())).captured.single
            as AuditLogFilter;
    expect(filter.action, 'DELETE');
  });

  test('내보내기가 거절되면 서버가 준 이유가 남고 목록은 그대로다', () async {
    stubLogs();
    when(() => repository.exportCsv(any())).thenThrow(
      const ServerFailure(
        message: '10,000건이 넘습니다. 기간을 좁혀 주세요.',
        code: 'INVALID_REQUEST',
      ),
    );

    await viewModel.load();
    final ok = await viewModel.export();

    expect(ok, isFalse);
    // 서버 문장을 그대로 보여 줘야 무엇을 고칠지 알 수 있다.
    expect(viewModel.errorMessage, contains('기간을 좁혀'));
    expect(viewModel.state, ViewState.success);
    expect(saved, isEmpty);
  });

  test('기간을 지우면 전체 기간으로 돌아간다', () async {
    stubLogs();

    await viewModel.changePeriod(DateTime(2026, 8, 1), DateTime(2026, 8, 15));
    expect(viewModel.hasPeriod, isTrue);

    await viewModel.changePeriod(null, null);
    expect(viewModel.hasPeriod, isFalse);
    expect(viewModel.filter.from, isNull);
  });
}

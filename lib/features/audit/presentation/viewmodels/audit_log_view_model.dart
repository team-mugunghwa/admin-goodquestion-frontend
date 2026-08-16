import '../../../../core/config/app_config.dart';
import '../../../../core/network/page_result.dart';
import '../../../../core/presentation/base_view_model.dart';
import '../../../../core/utils/file_saver/file_saver.dart' as file_saver;
import '../../domain/audit_log.dart';

/// 브라우저에 파일을 저장하는 함수. 테스트가 갈아 끼울 수 있게 주입받습니다.
typedef SaveFile = void Function(String fileName, List<int> bytes, String mimeType);

class AuditLogViewModel extends BaseViewModel {
  AuditLogViewModel(this._repository, {SaveFile? saveFile})
    : _saveFile = saveFile ?? file_saver.saveFile;

  final AuditLogRepository _repository;
  final SaveFile _saveFile;

  PageResult<AuditLog> _logs = const PageResult.empty();
  AuditLogFilter _filter = const AuditLogFilter();

  PageResult<AuditLog> get logs => _logs;
  AuditLogFilter get filter => _filter;

  bool get hasPeriod => _filter.from != null || _filter.to != null;

  Future<void> load({int page = 0}) => guard(() async {
    _logs = await _repository.getLogs(
      filter: _filter,
      page: page,
      size: AppConfig.defaultPageSize,
    );
  });

  /// 필터를 바꾸면 첫 페이지부터 다시 봅니다. 조건을 좁혔는데 3페이지에 머물면
  /// 빈 화면이 뜹니다.
  Future<void> changeTargetType(String? targetType) {
    _filter = _filter.copyWith(targetType: () => targetType);
    return load();
  }

  Future<void> changeAction(String? action) {
    _filter = _filter.copyWith(action: () => action);
    return load();
  }

  Future<void> changeAdminEmail(String keyword) {
    final trimmed = keyword.trim();
    _filter = _filter.copyWith(
      adminEmail: () => trimmed.isEmpty ? null : trimmed,
    );
    return load();
  }

  Future<void> changePeriod(DateTime? from, DateTime? to) {
    _filter = _filter.copyWith(from: () => from, to: () => to);
    return load();
  }

  /// 지금 필터 그대로 CSV 를 받아 저장합니다.
  ///
  /// @return 성공 여부. 실패하면 [errorMessage] 에 서버가 준 이유가 담깁니다.
  /// 만 건이 넘으면 서버가 기간을 좁히라고 거절하는데, 그 문장을 그대로
  /// 보여 줘야 무엇을 고칠지 알 수 있습니다.
  Future<bool> export() => runTask(() async {
    final csv = await _repository.exportCsv(_filter);
    _saveFile(csv.fileName, csv.bytes, 'text/csv');
  });
}

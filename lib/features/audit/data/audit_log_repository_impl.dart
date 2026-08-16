import 'package:intl/intl.dart';

import '../../../core/error/exceptions.dart';
import '../../../core/error/failure.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/page_result.dart';
import '../domain/audit_log.dart';

class AuditLogRepositoryImpl implements AuditLogRepository {
  AuditLogRepositoryImpl(this._client);

  final DioClient _client;

  /// 서버가 받는 날짜 형식. 시각이 아니라 날짜만 보내고 해석은 서버가 한다.
  static final DateFormat _day = DateFormat('yyyy-MM-dd');

  @override
  Future<PageResult<AuditLog>> getLogs({
    AuditLogFilter filter = const AuditLogFilter(),
    int page = 0,
    int size = 20,
  }) => _guard(
    () => _client.get(
      '/audit-logs',
      queryParameters: {..._filterParams(filter), 'page': page, 'size': size},
      parse: (data) => PageResult.fromJson(
        data,
        (json) => AuditLog(
          id: json['id'] as String,
          adminEmail: json['adminEmail'] as String? ?? '',
          action: json['action'] as String? ?? '',
          targetType: json['targetType'] as String? ?? '',
          summary: json['summary'] as String?,
          ip: json['ip'] as String?,
          createdAt: DateTime.tryParse(
            json['createdAt'] as String? ?? '',
          )?.toLocal(),
        ),
      ),
    ),
  );

  @override
  Future<AuditLogCsv> exportCsv(AuditLogFilter filter) => _guard(() async {
    final bytes = await _client.getBytes(
      '/audit-logs/export',
      queryParameters: _filterParams(filter),
    );
    // 파일 이름은 서버와 같은 규칙으로 여기서 만든다. 응답 헤더를 파싱하는
    // 것보다 단순하고, 받은 시각이 이름에 남는 것이 목적이라 어긋날 일이 없다.
    final stamp = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
    return AuditLogCsv(fileName: 'audit_logs_$stamp.csv', bytes: bytes);
  });

  Map<String, dynamic> _filterParams(AuditLogFilter filter) => {
    if (filter.targetType != null) 'targetType': filter.targetType,
    if (filter.action != null) 'action': filter.action,
    if (filter.adminEmail != null && filter.adminEmail!.trim().isNotEmpty)
      'adminEmail': filter.adminEmail!.trim(),
    if (filter.from != null) 'from': _day.format(filter.from!),
    if (filter.to != null) 'to': _day.format(filter.to!),
  };

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on AppException catch (e) {
      throw Failure.fromException(e);
    }
  }
}

import '../../../core/error/exceptions.dart';
import '../../../core/error/failure.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/page_result.dart';
import '../domain/audit_log.dart';

class AuditLogRepositoryImpl implements AuditLogRepository {
  const AuditLogRepositoryImpl(this._client);

  final DioClient _client;

  @override
  Future<PageResult<AuditLog>> getLogs({
    String? targetType,
    int page = 0,
    int size = 20,
  }) async {
    try {
      return await _client.get(
        '/audit-logs',
        queryParameters: {
          if (targetType != null) 'targetType': targetType,
          'page': page,
          'size': size,
        },
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
      );
    } on AppException catch (e) {
      throw Failure.fromException(e);
    }
  }
}

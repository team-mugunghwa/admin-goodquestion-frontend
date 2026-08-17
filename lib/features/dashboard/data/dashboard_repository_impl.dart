import '../../../core/error/exceptions.dart';
import '../../../core/error/failure.dart';
import '../../../core/network/dio_client.dart';
import '../../support/domain/entities/inquiry.dart';
import '../domain/entities/dashboard_summary.dart';
import '../domain/repositories/dashboard_repository.dart';

/// 대시보드는 조회 하나뿐이라 DataSource 와 DTO 파일을 따로 만들지 않고
/// 이 파일 안에 둡니다. 파일을 나누는 것은 나눌 것이 있을 때 의미가 있습니다.
class DashboardRepositoryImpl implements DashboardRepository {
  const DashboardRepositoryImpl(this._client);

  final DioClient _client;

  @override
  Future<DashboardSummary> getSummary() async {
    try {
      return await _client.get<DashboardSummary>(
        '/dashboard',
        parse: (data) => _parse(_asMap(data)),
      );
    } on AppException catch (e) {
      throw Failure.fromException(e);
    }
  }

  static DashboardSummary _parse(Map<String, dynamic> json) {
    final users = _asMap(json['users']);
    final content = _asMap(json['content']);
    return DashboardSummary(
      users: UserStats(
        totalParents: _int(users['totalParents']),
        totalChildren: _int(users['totalChildren']),
        todayVisitors: _int(users['todayVisitors']),
        todayNewParents: _int(users['todayNewParents']),
        todayNewChildren: _int(users['todayNewChildren']),
        todaySessions: _int(users['todaySessions']),
        activeSessions: _int(users['activeSessions']),
      ),
      content: ContentStats(
        totalStories: _int(content['totalStories']),
        publishedStories: _int(content['publishedStories']),
        publishedNotices: _int(content['publishedNotices']),
        publishedGuides: _int(content['publishedGuides']),
        pendingInquiries: _int(content['pendingInquiries']),
      ),
      visitTrend: (json['visitTrend'] as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(
            (point) => DailyPoint(
              date: DateTime.parse(point['date'] as String),
              value: _int(point['value']),
            ),
          )
          .toList(),
      waitingInquiries: (json['waitingInquiries'] as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(
            (inquiry) => WaitingInquiry(
              id: inquiry['id'] as String,
              title: inquiry['title'] as String? ?? '',
              category: InquiryCategory.fromCode(inquiry['category'] as String?),
              createdAt: DateTime.tryParse(
                inquiry['createdAt'] as String? ?? '',
              )?.toLocal(),
            ),
          )
          .toList(),
      recentActivities: (json['recentActivities'] as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(
            (activity) => RecentActivity(
              adminEmail: activity['adminEmail'] as String? ?? '',
              action: activity['action'] as String? ?? '',
              targetType: activity['targetType'] as String? ?? '',
              summary: activity['summary'] as String?,
              createdAt: DateTime.tryParse(
                activity['createdAt'] as String? ?? '',
              )?.toLocal(),
            ),
          )
          .toList(),
    );
  }

  static Map<String, dynamic> _asMap(Object? value) =>
      value is Map<String, dynamic> ? value : const {};

  static int _int(Object? value) => (value as num?)?.toInt() ?? 0;
}

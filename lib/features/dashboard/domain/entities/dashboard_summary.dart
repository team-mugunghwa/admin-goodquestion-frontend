/// 대시보드가 한 번에 받아 오는 값 전체.
class DashboardSummary {
  const DashboardSummary({
    required this.users,
    required this.content,
    required this.visitTrend,
    required this.recentActivities,
  });

  final UserStats users;
  final ContentStats content;

  /// 최근 2주. 방문이 없던 날도 0으로 채워져 옵니다.
  final List<DailyPoint> visitTrend;
  final List<RecentActivity> recentActivities;
}

class UserStats {
  const UserStats({
    required this.totalParents,
    required this.totalChildren,
    required this.todayVisitors,
    required this.todayNewParents,
    required this.todayNewChildren,
    required this.todaySessions,
    required this.activeSessions,
  });

  final int totalParents;
  final int totalChildren;

  /// 오늘 다녀간 사람 수. 접속 횟수가 아닙니다.
  final int todayVisitors;
  final int todayNewParents;
  final int todayNewChildren;
  final int todaySessions;

  /// 지금 진행 중인 학습 세션.
  final int activeSessions;
}

class ContentStats {
  const ContentStats({
    required this.totalStories,
    required this.publishedStories,
    required this.publishedNotices,
    required this.publishedGuides,
    required this.pendingInquiries,
  });

  final int totalStories;
  final int publishedStories;
  final int publishedNotices;
  final int publishedGuides;

  /// 미답변 문의. 대시보드에서 가장 먼저 봐야 할 값입니다.
  final int pendingInquiries;
}

class DailyPoint {
  const DailyPoint({required this.date, required this.value});

  final DateTime date;
  final int value;
}

class RecentActivity {
  const RecentActivity({
    required this.adminEmail,
    required this.action,
    required this.targetType,
    required this.summary,
    required this.createdAt,
  });

  final String adminEmail;
  final String action;
  final String targetType;
  final String? summary;
  final DateTime? createdAt;
}

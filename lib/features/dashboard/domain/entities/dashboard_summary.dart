import '../../../support/domain/entities/inquiry.dart';

/// 대시보드가 한 번에 받아 오는 값 전체.
class DashboardSummary {
  const DashboardSummary({
    required this.users,
    required this.content,
    required this.visitTrend,
    required this.waitingInquiries,
    required this.recentActivities,
  });

  final UserStats users;
  final ContentStats content;

  /// 최근 2주. 방문이 없던 날도 0으로 채워져 옵니다.
  final List<DailyPoint> visitTrend;

  /// 답변을 기다리는 문의. 오래 기다린 순이라 맨 위가 가장 급합니다.
  final List<WaitingInquiry> waitingInquiries;
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

/// 답변을 기다리는 문의 한 줄.
///
/// 미답변 건수는 "얼마나 남았는가"만 답합니다. 사흘 기다린 문의와 방금 들어온 문의가
/// 같은 숫자에 섞여 있어서, 급한 것이 있는지는 문의 목록을 열어야 알 수 있었습니다.
class WaitingInquiry {
  const WaitingInquiry({
    required this.id,
    required this.title,
    required this.category,
    this.createdAt,
  });

  final String id;
  final String title;
  final InquiryCategory category;

  /// 접수 시각. 화면이 여기서 대기 시간을 계산합니다.
  final DateTime? createdAt;
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

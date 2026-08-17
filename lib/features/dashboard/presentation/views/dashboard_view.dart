import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/di/injector.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formats.dart';
import '../../../../core/widgets/app_page.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../domain/entities/dashboard_summary.dart';
import '../../domain/usecases/get_dashboard_summary_use_case.dart';
import '../viewmodels/dashboard_view_model.dart';
import '../widgets/stat_card.dart';
import '../widgets/visit_trend_chart.dart';

class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) =>
          DashboardViewModel(getIt<GetDashboardSummaryUseCase>())..load(),
      child: const _DashboardBody(),
    );
  }
}

class _DashboardBody extends StatelessWidget {
  const _DashboardBody();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<DashboardViewModel>();

    return AppPage(
      title: '대시보드',
      description: '오늘 기준 서비스 현황입니다.',
      actions: [
        OutlinedButton.icon(
          onPressed: vm.isLoading
              ? null
              : () => context.read<DashboardViewModel>().load(),
          icon: const Icon(AppIcons.refresh, size: AppSizes.icon),
          label: const Text('새로고침'),
        ),
      ],
      child: AppStateView(
        state: vm.state,
        errorMessage: vm.errorMessage,
        onRetry: () => context.read<DashboardViewModel>().load(),
        builder: (context) => _Content(summary: vm.summary!),
      ),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({required this.summary});

  final DashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    final users = summary.users;
    final content = summary.content;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 조치가 필요한 값을 맨 앞에 둡니다. 대시보드를 여는 이유의 절반은
        // "지금 내가 해야 할 일이 있는가"입니다.
        _CardGrid(
          children: [
            StatCard(
              label: '미답변 문의',
              value: content.pendingInquiries,
              hint: '답변을 기다리는 문의',
              tone: AppColors.danger,
              onTap: () => context.go(AppRoutes.inquiries),
            ),
            StatCard(
              label: '총 사용자',
              value: users.totalParents,
              hint: '아이 ${Formats.count(users.totalChildren)}명',
              onTap: () => context.go(AppRoutes.members),
            ),
            StatCard(
              label: '오늘 방문자',
              value: users.todayVisitors,
              hint: '접속 횟수가 아니라 사람 수',
            ),
            StatCard(
              label: '오늘 신규 가입',
              value: users.todayNewParents,
              hint: '아이 등록 ${Formats.count(users.todayNewChildren)}건',
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        _CardGrid(
          children: [
            StatCard(
              label: '오늘 시작한 이야기',
              value: users.todaySessions,
              hint: '진행 중 ${Formats.count(users.activeSessions)}건',
            ),
            StatCard(
              label: '공개 중인 이야기',
              value: content.publishedStories,
              hint: '전체 ${Formats.count(content.totalStories)}편',
              onTap: () => context.go(AppRoutes.stories),
            ),
            StatCard(
              label: '공개 중인 공지',
              value: content.publishedNotices,
              onTap: () => context.go(AppRoutes.notices),
            ),
            StatCard(
              label: '공개 중인 이용안내',
              value: content.publishedGuides,
              onTap: () => context.go(AppRoutes.guides),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),

        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 1080;
            final trend = AppCard(
              title: '최근 2주 방문자',
              child: VisitTrendChart(points: summary.visitTrend),
            );
            final waiting = AppCard(
              title: '답변을 기다리는 문의',
              trailing: TextButton(
                onPressed: () => context.go(AppRoutes.inquiries),
                child: const Text('전체 보기'),
              ),
              child: _WaitingInquiries(items: summary.waitingInquiries),
            );
            final activities = AppCard(
              title: '최근 관리자 활동',
              child: _RecentActivities(items: summary.recentActivities),
            );

            if (!wide) {
              return Column(
                children: [
                  trend,
                  const SizedBox(height: AppSpacing.lg),
                  waiting,
                  const SizedBox(height: AppSpacing.lg),
                  activities,
                ],
              );
            }
            // 넓은 화면에서는 왼쪽 열이 그래프 하나뿐이라 활동 목록(최대 10줄)보다
            // 훨씬 짧아 아래가 비었습니다. 그 자리에 문의를 넣어 높이도 맞춥니다.
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      trend,
                      const SizedBox(height: AppSpacing.lg),
                      waiting,
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(flex: 2, child: activities),
              ],
            );
          },
        ),
      ],
    );
  }
}

/// 지표 카드를 폭에 따라 4열 / 2열로 나눕니다.
class _CardGrid extends StatelessWidget {
  const _CardGrid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1080 ? 4 : 2;
        const spacing = AppSpacing.lg;
        final width =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final child in children) SizedBox(width: width, child: child),
          ],
        );
      },
    );
  }
}

/// 답변을 기다리는 문의. 오래 기다린 순서라 맨 위가 가장 급합니다.
///
/// 대기 시간을 상대 시간으로 적습니다. 표가 아니라 목록이라 줄 사이의 선후를 가릴
/// 필요가 없고, "사흘 전"이 "2026-08-14 09:12"보다 급한 정도를 바로 보여줍니다.
class _WaitingInquiries extends StatelessWidget {
  const _WaitingInquiries({required this.items});

  final List<WaitingInquiry> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
        child: Text('기다리는 문의가 없습니다', style: AppTypography.caption),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final inquiry in items)
          InkWell(
            onTap: () => context.go(AppRoutes.inquiryDetailOf(inquiry.id)),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          inquiry.title,
                          style: AppTypography.body,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          inquiry.category.label,
                          style: AppTypography.caption,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Text(
                    Formats.relative(inquiry.createdAt),
                    style: AppTypography.caption,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _RecentActivities extends StatelessWidget {
  const _RecentActivities({required this.items});

  final List<RecentActivity> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
        child: Text('아직 기록이 없습니다', style: AppTypography.caption),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final activity in items)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.lg),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        activity.summary ?? '${activity.targetType} ${activity.action}',
                        style: AppTypography.body,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(activity.adminEmail, style: AppTypography.caption),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Text(
                  Formats.relative(activity.createdAt),
                  style: AppTypography.caption,
                ),
              ],
            ),
          ),
      ],
    );
  }
}

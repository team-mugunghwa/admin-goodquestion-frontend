import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/di/injector.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formats.dart';
import '../../../../core/widgets/app_data_table.dart';
import '../../../../core/widgets/app_dialogs.dart';
import '../../../../core/widgets/app_form.dart';
import '../../../../core/widgets/app_page.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../domain/audit_log.dart';
import '../viewmodels/audit_log_view_model.dart';

/// 감사 로그.
class AuditLogView extends StatelessWidget {
  const AuditLogView({super.key});

  /// 필터 목록. 서버가 주는 targetType 문자열을 그대로 씁니다.
  static const Map<String, String> _targetTypes = {
    'NOTICE': '공지',
    'GUIDE': '이용안내',
    'STORY': '이야기',
    'SCENE': '장면',
    'CHARACTER': '캐릭터',
    'INQUIRY': '문의',
    'PARENT': '사용자',
    'ADMIN_ACCOUNT': '관리자 계정',
    'DATABASE': '데이터베이스',
    'AUDIT_LOG': '감사 로그',
  };

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuditLogViewModel(getIt<AuditLogRepository>())..load(),
      child: Builder(
        builder: (context) {
          final vm = context.watch<AuditLogViewModel>();
          return AppPage(
            title: '감사 로그',
            description:
                '상태를 바꾼 조작과 개인정보 데이터 조회를 남깁니다. CSV 내보내기도 여기 기록됩니다.',
            scrollable: false,
            actions: [
              FilledButton.icon(
                onPressed: vm.isBusy
                    ? null
                    : () async {
                        final viewModel = context.read<AuditLogViewModel>();
                        final messenger = context;
                        final ok = await viewModel.export();
                        if (!messenger.mounted) return;
                        showResultSnackBar(
                          messenger,
                          success: ok,
                          message: ok
                              ? 'CSV 를 내려받았습니다. 이 내보내기도 로그에 남습니다.'
                              : viewModel.errorMessage ?? '내보내기에 실패했습니다.',
                        );
                        if (ok) await viewModel.load();
                      },
                icon: const Icon(AppIcons.download, size: AppSizes.icon),
                label: const Text('CSV 내보내기'),
              ),
            ],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppFilterBar(
                  children: [
                    AppFilterDropdown<String>(
                      value: vm.filter.targetType,
                      items: _targetTypes,
                      allLabel: '전체 대상',
                      width: 170,
                      onChanged: (value) => context
                          .read<AuditLogViewModel>()
                          .changeTargetType(value),
                    ),
                    AppFilterDropdown<String>(
                      value: vm.filter.action,
                      items: AuditLog.actionLabels,
                      allLabel: '전체 조작',
                      width: 150,
                      onChanged: (value) =>
                          context.read<AuditLogViewModel>().changeAction(value),
                    ),
                    AppSearchField(
                      width: 240,
                      hintText: '관리자 이메일 (부분 일치)',
                      initialValue: vm.filter.adminEmail,
                      onSubmitted: (value) => context
                          .read<AuditLogViewModel>()
                          .changeAdminEmail(value),
                    ),
                    const _PeriodButton(),
                  ],
                ),
                Expanded(
                  child: SingleChildScrollView(
                    child: AppCard(
                      padding: EdgeInsets.zero,
                      child: AppStateView(
                        state: vm.state,
                        errorMessage: vm.errorMessage,
                        onRetry: () => context.read<AuditLogViewModel>().load(),
                        isEmpty: vm.logs.isEmpty,
                        emptyTitle: '조건에 맞는 기록이 없습니다',
                        builder: (context) => AppPagedTable<AuditLog>(
                          result: vm.logs,
                          rowKey: (log) => log.id,
                          onPageChanged: (page) => context
                              .read<AuditLogViewModel>()
                              .load(page: page),
                          columns: [
                            AppColumn(
                              label: '시각',
                              width: 150,
                              cellBuilder: (context, log) => Text(
                                Formats.dateTime(log.createdAt),
                                style: AppTypography.caption,
                              ),
                            ),
                            AppColumn(
                              label: '관리자',
                              flex: 2,
                              cellBuilder: (context, log) => Text(
                                log.adminEmail,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            AppColumn(
                              label: '대상',
                              width: 110,
                              cellBuilder: (context, log) =>
                                  Text(log.targetLabel),
                            ),
                            AppColumn(
                              label: '조작',
                              width: 100,
                              cellBuilder: (context, log) =>
                                  Text(log.actionLabel),
                            ),
                            AppColumn(
                              label: '내용',
                              flex: 4,
                              cellBuilder: (context, log) => Text(
                                log.summary ?? '-',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            AppColumn(
                              label: 'IP',
                              width: 120,
                              cellBuilder: (context, log) => Text(
                                log.ip ?? '-',
                                style: AppTypography.caption,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// 기간 필터. 누르면 범위 달력이 뜨고, 걸려 있으면 지우기가 함께 보입니다.
class _PeriodButton extends StatelessWidget {
  const _PeriodButton();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AuditLogViewModel>();
    final from = vm.filter.from;
    final to = vm.filter.to;

    final label = vm.hasPeriod
        ? '${Formats.date(from)} ~ ${Formats.date(to)}'
        : '기간';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        OutlinedButton.icon(
          onPressed: () async {
            final viewModel = context.read<AuditLogViewModel>();
            final now = DateTime.now();
            final picked = await showDateRangePicker(
              context: context,
              // 감사 로그 테이블이 생긴 뒤면 충분한 하한입니다.
              firstDate: DateTime(2025, 1, 1),
              lastDate: now,
              // 앱 전체가 한국어 로케일이라 달력도 한국어로 나옵니다.
              initialDateRange: from != null && to != null
                  ? DateTimeRange(start: from, end: to)
                  : null,
            );
            if (picked == null) return;
            await viewModel.changePeriod(picked.start, picked.end);
          },
          icon: const Icon(AppIcons.period, size: AppSizes.icon),
          label: Text(label),
        ),
        if (vm.hasPeriod)
          IconButton(
            tooltip: '기간 지우기',
            onPressed: () =>
                context.read<AuditLogViewModel>().changePeriod(null, null),
            icon: const Icon(AppIcons.close, size: AppSizes.icon),
          ),
      ],
    );
  }
}

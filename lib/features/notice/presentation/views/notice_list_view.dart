import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/di/injector.dart';
import '../../../../core/domain/content_status.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formats.dart';
import '../../../../core/widgets/app_data_table.dart';
import '../../../../core/widgets/app_dialogs.dart';
import '../../../../core/widgets/app_form.dart';
import '../../../../core/widgets/app_page.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../../core/widgets/app_status_chip.dart';
import '../../domain/entities/notice.dart';
import '../../domain/usecases/notice_use_cases.dart';
import '../viewmodels/notice_list_view_model.dart';

class NoticeListView extends StatelessWidget {
  const NoticeListView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => NoticeListViewModel(
        getNotices: getIt<GetNoticesUseCase>(),
        deleteNotice: getIt<DeleteNoticeUseCase>(),
      )..load(),
      child: const _NoticeListBody(),
    );
  }
}

class _NoticeListBody extends StatelessWidget {
  const _NoticeListBody();

  Future<void> _confirmDelete(BuildContext context, NoticeSummary notice) async {
    final confirmed = await showConfirmDialog(
      context,
      title: '공지를 삭제할까요?',
      message: '"${notice.title}"\n\n삭제하면 되돌릴 수 없습니다. 사용자에게 보이지 않게만 하려면 '
          '상태를 보관으로 바꾸세요.',
      confirmLabel: '삭제',
      destructive: true,
    );
    if (!confirmed || !context.mounted) return;

    final vm = context.read<NoticeListViewModel>();
    final ok = await vm.delete(notice.id);
    if (!context.mounted) return;
    showResultSnackBar(
      context,
      success: ok,
      message: ok ? '공지를 삭제했습니다.' : (vm.errorMessage ?? '삭제하지 못했습니다.'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<NoticeListViewModel>();

    return AppPage(
      title: '공지사항 관리',
      description: '공개 상태로 두면 사용자 앱의 공지 목록에 그대로 나갑니다.',
      scrollable: false,
      actions: [
        FilledButton.icon(
          onPressed: () => context.go(AppRoutes.noticeNew),
          icon: const Icon(AppIcons.add, size: AppSizes.icon),
          label: const Text('공지 작성'),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppFilterBar(
            children: [
              AppSearchField(
                hintText: '제목으로 검색',
                initialValue: vm.keyword,
                onSubmitted: (value) =>
                    context.read<NoticeListViewModel>().search(value),
              ),
              AppFilterDropdown<ContentStatus>(
                value: vm.status,
                items: ContentStatus.labels,
                allLabel: '전체 상태',
                onChanged: (value) =>
                    context.read<NoticeListViewModel>().changeStatus(value),
              ),
            ],
          ),
          Expanded(
            child: SingleChildScrollView(
              child: AppCard(
                padding: EdgeInsets.zero,
                child: AppStateView(
                  state: vm.state,
                  errorMessage: vm.errorMessage,
                  onRetry: () => context.read<NoticeListViewModel>().load(),
                  isEmpty: vm.notices.isEmpty,
                  emptyTitle: '공지가 없습니다',
                  emptyDescription: '첫 공지를 작성해 사용자에게 알려 주세요.',
                  emptyAction: FilledButton.icon(
                    onPressed: () => context.go(AppRoutes.noticeNew),
                    icon: const Icon(AppIcons.add, size: AppSizes.icon),
                    label: const Text('공지 작성'),
                  ),
                  builder: (context) => AppPagedTable<NoticeSummary>(
                    result: vm.notices,
                    rowKey: (notice) => notice.id,
                    onRowTap: (notice) =>
                        context.go(AppRoutes.noticeDetailOf(notice.id)),
                    onPageChanged: (page) =>
                        context.read<NoticeListViewModel>().load(page: page),
                    columns: [
                      AppColumn(
                        label: '제목',
                        flex: 4,
                        cellBuilder: (context, notice) => Row(
                          children: [
                            if (notice.pinned)
                              const Padding(
                                padding: EdgeInsets.only(right: AppSpacing.sm),
                                child: Icon(
                                  Icons.push_pin_rounded,
                                  size: 14,
                                  color: AppColors.warning,
                                ),
                              ),
                            Flexible(
                              child: Text(
                                notice.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.bodyStrong,
                              ),
                            ),
                          ],
                        ),
                      ),
                      AppColumn(
                        label: '분류',
                        width: 100,
                        cellBuilder: (context, notice) =>
                            Text(notice.category.label),
                      ),
                      AppColumn(
                        label: '상태',
                        width: 90,
                        cellBuilder: (context, notice) => AppStatusChip(
                          label: notice.status.label,
                          tone: notice.status.tone,
                        ),
                      ),
                      AppColumn(
                        label: '조회',
                        width: 80,
                        alignment: Alignment.centerRight,
                        cellBuilder: (context, notice) => Text(
                          Formats.count(notice.viewCount),
                          style: AppTypography.number,
                        ),
                      ),
                      AppColumn(
                        label: '작성자',
                        width: 110,
                        cellBuilder: (context, notice) =>
                            Text(notice.authorName ?? '-'),
                      ),
                      AppColumn(
                        label: '공개일',
                        width: 110,
                        cellBuilder: (context, notice) => Text(
                          Formats.date(notice.publishedAt),
                          style: AppTypography.caption,
                        ),
                      ),
                      AppColumn(
                        label: '',
                        width: 48,
                        cellBuilder: (context, notice) => IconButton(
                          tooltip: '삭제',
                          icon: const Icon(AppIcons.delete, size: AppSizes.icon),
                          color: AppColors.ink500,
                          onPressed: vm.isBusy
                              ? null
                              : () => _confirmDelete(context, notice),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

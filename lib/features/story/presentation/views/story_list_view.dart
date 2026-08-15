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
import '../../../../core/widgets/app_data_table.dart';
import '../../../../core/widgets/app_dialogs.dart';
import '../../../../core/widgets/app_form.dart';
import '../../../../core/widgets/app_page.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../../core/widgets/app_status_chip.dart';
import '../../domain/entities/story.dart';
import '../../domain/usecases/story_use_cases.dart';
import '../viewmodels/story_list_view_model.dart';

class StoryListView extends StatelessWidget {
  const StoryListView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => StoryListViewModel(
        getStories: getIt<GetStoriesUseCase>(),
        deleteStory: getIt<DeleteStoryUseCase>(),
      )..load(),
      child: const _StoryListBody(),
    );
  }
}

class _StoryListBody extends StatelessWidget {
  const _StoryListBody();

  Future<void> _confirmDelete(BuildContext context, StorySummary story) async {
    final confirmed = await showConfirmDialog(
      context,
      title: '이야기를 삭제할까요?',
      message: '"${story.title}"\n\n장면과 캐릭터도 함께 지워집니다. '
          '이미 진행한 기록이 있으면 삭제되지 않습니다 - 그때는 보관 상태로 바꾸세요.',
      confirmLabel: '삭제',
      destructive: true,
    );
    if (!confirmed || !context.mounted) return;

    final vm = context.read<StoryListViewModel>();
    final ok = await vm.delete(story.id);
    if (!context.mounted) return;
    showResultSnackBar(
      context,
      success: ok,
      message: ok ? '이야기를 삭제했습니다.' : (vm.errorMessage ?? '삭제하지 못했습니다.'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<StoryListViewModel>();

    return AppPage(
      title: '이야기 관리',
      description: '공개한 이야기가 사용자 앱의 이야기 목록에 나갑니다.',
      scrollable: false,
      actions: [
        FilledButton.icon(
          onPressed: () => context.go(AppRoutes.storyNew),
          icon: const Icon(AppIcons.add, size: AppSizes.icon),
          label: const Text('이야기 추가'),
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
                    context.read<StoryListViewModel>().search(value),
              ),
              AppFilterDropdown<StoryStatus>(
                value: vm.status,
                items: StoryStatus.labels,
                allLabel: '전체 상태',
                onChanged: (value) =>
                    context.read<StoryListViewModel>().changeStatus(value),
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
                  onRetry: () => context.read<StoryListViewModel>().load(),
                  isEmpty: vm.stories.isEmpty,
                  emptyTitle: '이야기가 없습니다',
                  emptyDescription: '이야기를 만들고 장면을 추가한 뒤 공개하세요.',
                  emptyAction: FilledButton.icon(
                    onPressed: () => context.go(AppRoutes.storyNew),
                    icon: const Icon(AppIcons.add, size: AppSizes.icon),
                    label: const Text('이야기 추가'),
                  ),
                  builder: (context) => AppPagedTable<StorySummary>(
                    result: vm.stories,
                    rowKey: (story) => story.id,
                    onRowTap: (story) =>
                        context.go(AppRoutes.storyDetailOf(story.id)),
                    onPageChanged: (page) =>
                        context.read<StoryListViewModel>().load(page: page),
                    columns: [
                      AppColumn(
                        label: '제목',
                        flex: 3,
                        cellBuilder: (context, story) => Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              story.title,
                              style: AppTypography.bodyStrong,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              Formats.oneLine(story.summary, max: 60),
                              style: AppTypography.caption,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      AppColumn(
                        label: '주제',
                        flex: 2,
                        cellBuilder: (context, story) => Text(
                          story.topics.isEmpty ? '-' : story.topics.join(', '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.caption,
                        ),
                      ),
                      AppColumn(
                        label: '장면',
                        width: 70,
                        alignment: Alignment.centerRight,
                        cellBuilder: (context, story) => Text(
                          '${story.sceneCount}',
                          style: AppTypography.number.copyWith(
                            // 장면이 없으면 공개할 수 없습니다. 목록에서 바로 보이게 합니다.
                            color: story.sceneCount == 0
                                ? AppColors.warning
                                : AppColors.ink900,
                          ),
                        ),
                      ),
                      AppColumn(
                        label: '예상 시간',
                        width: 90,
                        cellBuilder: (context, story) => Text(
                          story.estimatedMinutes == null
                              ? '-'
                              : '${story.estimatedMinutes}분',
                          style: AppTypography.caption,
                        ),
                      ),
                      AppColumn(
                        label: '상태',
                        width: 90,
                        cellBuilder: (context, story) => AppStatusChip(
                          label: story.status.label,
                          tone: story.status.tone,
                        ),
                      ),
                      AppColumn(
                        label: '수정일',
                        width: 110,
                        cellBuilder: (context, story) => Text(
                          Formats.date(story.updatedAt),
                          style: AppTypography.caption,
                        ),
                      ),
                      AppColumn(
                        label: '',
                        width: 48,
                        cellBuilder: (context, story) => IconButton(
                          tooltip: '삭제',
                          icon: const Icon(AppIcons.delete, size: AppSizes.icon),
                          color: AppColors.ink500,
                          onPressed: vm.isBusy
                              ? null
                              : () => _confirmDelete(context, story),
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
  }
}

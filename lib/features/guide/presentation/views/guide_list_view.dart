import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/di/injector.dart';
import '../../../../core/domain/content_status.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formats.dart';
import '../../../../core/widgets/app_dialogs.dart';
import '../../../../core/widgets/app_form.dart';
import '../../../../core/widgets/app_page.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../../core/widgets/app_status_chip.dart';
import '../../domain/entities/guide.dart';
import '../../domain/usecases/guide_use_cases.dart';
import '../viewmodels/guide_list_view_model.dart';
import '../widgets/guide_edit_dialog.dart';

/// 이용안내 관리.
///
/// 카테고리별로 묶고, 그 안에서 드래그로 순서를 바꿉니다. 사용자 앱이 정확히 이
/// 순서대로 보여주므로 화면 모양이 결과와 같습니다.
class GuideListView extends StatelessWidget {
  const GuideListView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => GuideListViewModel(
        getGuides: getIt<GetGuidesUseCase>(),
        createGuide: getIt<CreateGuideUseCase>(),
        updateGuide: getIt<UpdateGuideUseCase>(),
        reorderGuides: getIt<ReorderGuidesUseCase>(),
        deleteGuide: getIt<DeleteGuideUseCase>(),
      )..load(),
      child: const _GuideListBody(),
    );
  }
}

class _GuideListBody extends StatelessWidget {
  const _GuideListBody();

  Future<void> _create(BuildContext context, {GuideCategory? category}) async {
    final draft = await showGuideEditDialog(context, defaultCategory: category);
    if (draft == null || !context.mounted) return;

    final vm = context.read<GuideListViewModel>();
    final ok = await vm.create(
      category: draft.category,
      title: draft.title,
      content: draft.content,
      status: draft.status,
    );
    if (!context.mounted) return;
    showResultSnackBar(
      context,
      success: ok,
      message: ok ? '이용안내를 추가했습니다.' : (vm.errorMessage ?? '추가하지 못했습니다.'),
    );
  }

  Future<void> _edit(BuildContext context, Guide guide) async {
    final draft = await showGuideEditDialog(context, guide: guide);
    if (draft == null || !context.mounted) return;

    final vm = context.read<GuideListViewModel>();
    final ok = await vm.update(
      guideId: guide.id,
      category: draft.category,
      title: draft.title,
      content: draft.content,
      status: draft.status,
    );
    if (!context.mounted) return;
    showResultSnackBar(
      context,
      success: ok,
      message: ok ? '저장했습니다.' : (vm.errorMessage ?? '저장하지 못했습니다.'),
    );
  }

  Future<void> _delete(BuildContext context, Guide guide) async {
    final confirmed = await showConfirmDialog(
      context,
      title: '이용안내를 삭제할까요?',
      message: '"${guide.title}"\n\n삭제하면 되돌릴 수 없습니다.',
      confirmLabel: '삭제',
      destructive: true,
    );
    if (!confirmed || !context.mounted) return;

    final vm = context.read<GuideListViewModel>();
    final ok = await vm.delete(guide.id);
    if (!context.mounted) return;
    showResultSnackBar(
      context,
      success: ok,
      message: ok ? '삭제했습니다.' : (vm.errorMessage ?? '삭제하지 못했습니다.'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<GuideListViewModel>();
    final grouped = vm.grouped;

    return AppPage(
      title: '이용안내 관리',
      description: '공개한 문서가 사용자 앱의 이용안내에 이 순서 그대로 나갑니다.',
      actions: [
        FilledButton.icon(
          onPressed: () => _create(context),
          icon: const Icon(AppIcons.add, size: AppSizes.icon),
          label: const Text('문서 추가'),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppFilterBar(
            children: [
              AppFilterDropdown<GuideCategory>(
                value: vm.category,
                items: GuideCategory.labels,
                allLabel: '전체 분류',
                width: 180,
                onChanged: (value) =>
                    context.read<GuideListViewModel>().changeCategory(value),
              ),
              AppFilterDropdown<ContentStatus>(
                value: vm.status,
                items: ContentStatus.labels,
                allLabel: '전체 상태',
                onChanged: (value) =>
                    context.read<GuideListViewModel>().changeStatus(value),
              ),
            ],
          ),
          AppStateView(
            state: vm.state,
            errorMessage: vm.errorMessage,
            onRetry: () => context.read<GuideListViewModel>().load(),
            isEmpty: vm.guides.isEmpty,
            emptyTitle: '이용안내가 없습니다',
            emptyDescription: '자주 묻는 내용을 문서로 만들어 두면 문의가 줄어듭니다.',
            emptyAction: FilledButton.icon(
              onPressed: () => _create(context),
              icon: const Icon(AppIcons.add, size: AppSizes.icon),
              label: const Text('문서 추가'),
            ),
            builder: (context) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final entry in grouped.entries)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                    child: _CategorySection(
                      category: entry.key,
                      guides: entry.value,
                      onAdd: () => _create(context, category: entry.key),
                      onEdit: (guide) => _edit(context, guide),
                      onDelete: (guide) => _delete(context, guide),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CategorySection extends StatelessWidget {
  const _CategorySection({
    required this.category,
    required this.guides,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
  });

  final GuideCategory category;
  final List<Guide> guides;
  final VoidCallback onAdd;
  final ValueChanged<Guide> onEdit;
  final ValueChanged<Guide> onDelete;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      title: category.label,
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      trailing: TextButton.icon(
        onPressed: onAdd,
        icon: const Icon(AppIcons.add, size: AppSizes.icon),
        label: const Text('추가'),
      ),
      child: ReorderableListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        buildDefaultDragHandles: false,
        itemCount: guides.length,
        // onReorderItem 으로 바꾸면 인덱스 보정 규칙이 달라져 순서가 한 칸씩
        // 어긋납니다. 아래 보정과 함께 한 번에 옮겨야 해서 지금은 그대로 둡니다.
        // ignore: deprecated_member_use
        onReorder: (oldIndex, newIndex) {
          // ReorderableListView 는 아래로 옮길 때 newIndex 가 하나 큽니다.
          // 이 보정을 빼먹으면 한 칸씩 어긋난 순서가 저장됩니다.
          final adjusted = newIndex > oldIndex ? newIndex - 1 : newIndex;
          final ids = guides.map((guide) => guide.id).toList();
          final moved = ids.removeAt(oldIndex);
          ids.insert(adjusted, moved);
          context.read<GuideListViewModel>().reorder(
            category: category,
            guideIds: ids,
          );
        },
        itemBuilder: (context, index) {
          final guide = guides[index];
          return _GuideRow(
            key: ValueKey(guide.id),
            index: index,
            guide: guide,
            onEdit: () => onEdit(guide),
            onDelete: () => onDelete(guide),
          );
        },
      ),
    );
  }
}

class _GuideRow extends StatelessWidget {
  const _GuideRow({
    required this.index,
    required this.guide,
    required this.onEdit,
    required this.onDelete,
    super.key,
  });

  final int index;
  final Guide guide;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.ink100)),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          ReorderableDragStartListener(
            index: index,
            child: const MouseRegion(
              cursor: SystemMouseCursors.grab,
              child: Padding(
                padding: EdgeInsets.only(right: AppSpacing.md),
                child: Icon(
                  AppIcons.dragHandle,
                  size: AppSizes.icon,
                  color: AppColors.ink400,
                ),
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(guide.title, style: AppTypography.bodyStrong),
                const SizedBox(height: 2),
                Text(
                  Formats.oneLine(guide.content, max: 100),
                  style: AppTypography.caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          AppStatusChip(label: guide.status.label, tone: guide.status.tone),
          const SizedBox(width: AppSpacing.sm),
          IconButton(
            tooltip: '수정',
            onPressed: onEdit,
            icon: const Icon(AppIcons.edit, size: AppSizes.icon),
            color: AppColors.ink500,
          ),
          IconButton(
            tooltip: '삭제',
            onPressed: onDelete,
            icon: const Icon(AppIcons.delete, size: AppSizes.icon),
            color: AppColors.ink500,
          ),
        ],
      ),
    );
  }
}

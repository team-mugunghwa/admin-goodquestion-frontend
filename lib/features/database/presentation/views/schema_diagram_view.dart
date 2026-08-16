import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/di/injector.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_form.dart';
import '../../../../core/widgets/app_page.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../domain/usecases/database_use_cases.dart';
import '../diagram/relation_painter.dart';
import '../diagram/table_box.dart';
import '../viewmodels/schema_diagram_view_model.dart';

/// 테이블 관계도.
///
/// 목록은 "무엇이 있는가"를 알려 주지만 "무엇이 무엇에 딸려 있는가"는 알려 주지
/// 못합니다. 아이가 보호자에 딸리고 학습 결과가 아이에 딸린다는 것은 한 장으로
/// 봐야 들어옵니다.
class SchemaDiagramView extends StatelessWidget {
  const SchemaDiagramView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SchemaDiagramViewModel(getIt<GetRelationsUseCase>())..load(),
      child: const _SchemaDiagramBody(),
    );
  }
}

class _SchemaDiagramBody extends StatefulWidget {
  const _SchemaDiagramBody();

  @override
  State<_SchemaDiagramBody> createState() => _SchemaDiagramBodyState();
}

class _SchemaDiagramBodyState extends State<_SchemaDiagramBody> {
  final TransformationController _transform = TransformationController();

  @override
  void dispose() {
    _transform.dispose();
    super.dispose();
  }

  void _resetView() => _transform.value = Matrix4.identity();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SchemaDiagramViewModel>();

    return AppPage(
      title: '테이블 관계도',
      description:
          '어떤 테이블이 어디에 딸려 있는지 한 장으로 봅니다. 왼쪽이 가리켜지는 쪽, 오른쪽이 가리키는 쪽입니다.',
      backRoute: AppRoutes.database,
      scrollable: false,
      actions: [
        TextButton.icon(
          onPressed: _resetView,
          icon: const Icon(AppIcons.refresh, size: AppSizes.icon),
          label: const Text('화면 맞춤'),
        ),
      ],
      child: AppStateView(
        state: vm.state,
        errorMessage: vm.errorMessage,
        onRetry: () => context.read<SchemaDiagramViewModel>().load(),
        isEmpty: vm.layout.isEmpty,
        emptyTitle: '그릴 관계가 없습니다',
        builder: (context) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _GroupFilter(viewModel: vm, onChanged: _resetView),
            Expanded(child: _Canvas(viewModel: vm, transform: _transform)),
            if (vm.focusedNode != null) _FocusPanel(viewModel: vm),
            const _Legend(),
          ],
        ),
      ),
    );
  }
}

class _GroupFilter extends StatelessWidget {
  const _GroupFilter({required this.viewModel, required this.onChanged});

  final SchemaDiagramViewModel viewModel;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    void select(String? group) {
      context.read<SchemaDiagramViewModel>().selectGroup(group);
      // 보이는 상자가 달라지면 배치도 달라집니다. 확대해 둔 자리를 그대로 두면
      // 엉뚱한 빈 곳을 보게 됩니다.
      onChanged();
    }

    return AppFilterBar(
      children: [
        _GroupChip(
          label: '전체 (${viewModel.graph.tables.length})',
          selected: viewModel.group == null,
          onTap: () => select(null),
        ),
        for (final group in viewModel.groups)
          _GroupChip(
            label: group,
            selected: viewModel.group == group,
            onTap: () => select(group),
          ),
        if (viewModel.group != null)
          Text(
            '맞닿은 테이블은 흐리게 함께 보여 줍니다.',
            style: AppTypography.caption,
          ),
      ],
    );
  }
}

class _GroupChip extends StatelessWidget {
  const _GroupChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      showCheckmark: false,
      labelStyle: AppTypography.caption.copyWith(
        color: selected ? AppColors.primary : AppColors.ink700,
      ),
      selectedColor: AppColors.primarySurface,
      backgroundColor: AppColors.surface,
      side: BorderSide(
        color: selected ? AppColors.primary : AppColors.ink100,
      ),
    );
  }
}

class _Canvas extends StatelessWidget {
  const _Canvas({required this.viewModel, required this.transform});

  final SchemaDiagramViewModel viewModel;
  final TransformationController transform;

  @override
  Widget build(BuildContext context) {
    final layout = viewModel.layout;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.canvas,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.ink100),
      ),
      clipBehavior: Clip.antiAlias,
      child: InteractiveViewer(
        transformationController: transform,
        // 관계도는 화면보다 큽니다. 축소해서 전체를 보거나 확대해서 컬럼 이름을
        // 읽는 두 가지를 다 해야 하므로 폭에 맞춰 줄이지 않습니다.
        constrained: false,
        minScale: 0.25,
        maxScale: 2,
        boundaryMargin: const EdgeInsets.all(200),
        child: SizedBox(
          width: layout.size.width,
          height: layout.size.height,
          child: Stack(
            children: [
              // 선이 먼저, 상자가 그 위에. 선이 상자를 가로질러도 가려집니다.
              Positioned.fill(
                child: CustomPaint(
                  painter: RelationPainter(
                    relations: layout.relations,
                    focusedTable: viewModel.focusedTable,
                  ),
                ),
              ),
              for (final placed in layout.tables)
                Positioned(
                  left: placed.rect.left,
                  top: placed.rect.top,
                  width: placed.rect.width,
                  height: placed.rect.height,
                  child: TableBox(
                    placed: placed,
                    focused: viewModel.focusedTable == placed.name,
                    onTap: () =>
                        context.read<SchemaDiagramViewModel>().focus(placed.name),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 누른 상자의 관계를 글로 적습니다. 선만으로는 어느 컬럼이 이어진 것인지 모릅니다.
class _FocusPanel extends StatelessWidget {
  const _FocusPanel({required this.viewModel});

  final SchemaDiagramViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final node = viewModel.focusedNode!;
    final relations = viewModel.focusedRelations;
    final outgoing = relations.where((r) => r.fromTable == node.name).toList();
    final incoming = relations.where((r) => r.toTable == node.name).toList();

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: AppCard(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${node.title} (${node.name})',
                    style: AppTypography.bodyStrong,
                  ),
                ),
                TextButton(
                  onPressed: () => context.go(AppRoutes.dbTableOf(node.name)),
                  child: const Text('테이블 열기'),
                ),
                IconButton(
                  tooltip: '선택 해제',
                  onPressed: () =>
                      context.read<SchemaDiagramViewModel>().focus(null),
                  icon: const Icon(AppIcons.close, size: AppSizes.icon),
                ),
              ],
            ),
            if (outgoing.isEmpty && incoming.isEmpty)
              Text('이어진 테이블이 없습니다.', style: AppTypography.caption)
            else
              Wrap(
                spacing: AppSpacing.xl,
                runSpacing: AppSpacing.xs,
                children: [
                  for (final relation in outgoing)
                    _RelationLine(
                      text:
                          '${relation.fromColumn} -> ${relation.toTable}.${relation.toColumn}',
                      leading: '가리킴',
                    ),
                  for (final relation in incoming)
                    _RelationLine(
                      text:
                          '${relation.fromTable}.${relation.fromColumn} -> ${relation.toColumn}',
                      leading: '가리켜짐',
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _RelationLine extends StatelessWidget {
  const _RelationLine({required this.text, required this.leading});

  final String text;
  final String leading;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          leading,
          style: AppTypography.caption.copyWith(color: AppColors.ink400),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(text, style: AppTypography.caption),
      ],
    );
  }
}

/// 선 모양이 무슨 뜻인지 적어 둡니다. 까마귀발 표기를 모르는 사람이 더 많습니다.
class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: Wrap(
        spacing: AppSpacing.xl,
        runSpacing: AppSpacing.xs,
        children: [
          Text(
            '갈래진 끝이 여러 건인 쪽, 막대로 끝나는 쪽이 하나뿐인 쪽입니다.',
            style: AppTypography.caption,
          ),
          Text(
            '막대 옆 동그라미는 없어도 되는 관계입니다.',
            style: AppTypography.caption,
          ),
          Text('상자를 누르면 그 테이블의 관계만 진하게 보입니다.',
              style: AppTypography.caption),
        ],
      ),
    );
  }
}

/// 목록 화면에서 관계도로 넘어가는 버튼.
class SchemaDiagramButton extends StatelessWidget {
  const SchemaDiagramButton({super.key});

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: () => context.go(AppRoutes.dbDiagram),
      icon: const Icon(AppIcons.diagram, size: AppSizes.icon),
      label: const Text('관계도 보기'),
    );
  }
}

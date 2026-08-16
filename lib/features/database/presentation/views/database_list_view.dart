import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formats.dart';
import '../../../../core/widgets/app_form.dart';
import '../../../../core/widgets/app_page.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../../core/widgets/app_status_chip.dart';
import '../../domain/entities/db_schema.dart';
import '../../domain/usecases/database_use_cases.dart';
import '../viewmodels/database_list_view_model.dart';

/// 데이터베이스 테이블 목록.
///
/// 백엔드를 보지 않는 팀원이 "이 서비스가 무엇을 저장하는가"를 훑는 첫 화면입니다.
/// 그래서 테이블 이름보다 **설명을 크게** 보여줍니다. `stardust_wallets` 라는 이름은
/// 찾는 사람에게 아무 뜻이 없고, "아이별 별가루 지갑"이 필요한 정보입니다.
class DatabaseListView extends StatelessWidget {
  const DatabaseListView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => DatabaseListViewModel(getIt<GetTablesUseCase>())..load(),
      child: const _DatabaseListBody(),
    );
  }
}

class _DatabaseListBody extends StatelessWidget {
  const _DatabaseListBody();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<DatabaseListViewModel>();
    final grouped = vm.grouped;

    return AppPage(
      title: '데이터베이스',
      description: '서비스가 저장하는 모든 테이블과 컬럼의 뜻, 실제 값을 볼 수 있습니다. 읽기 전용입니다.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppFilterBar(
            children: [
              AppSearchField(
                width: 360,
                hintText: '테이블 이름이나 설명으로 검색 (예: 별가루)',
                initialValue: vm.keyword,
                onSubmitted: (value) =>
                    context.read<DatabaseListViewModel>().search(value),
              ),
              if (vm.keyword.isNotEmpty)
                Text(
                  '${vm.tables.length} / ${vm.totalCount}개',
                  style: AppTypography.caption,
                ),
            ],
          ),
          AppStateView(
            state: vm.state,
            errorMessage: vm.errorMessage,
            onRetry: () => context.read<DatabaseListViewModel>().load(),
            isEmpty: vm.tables.isEmpty,
            emptyTitle: '찾는 테이블이 없습니다',
            emptyDescription: '다른 검색어로 찾아보세요.',
            builder: (context) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final entry in grouped.entries)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                    child: _GroupSection(group: entry.key, tables: entry.value),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GroupSection extends StatelessWidget {
  const _GroupSection({required this.group, required this.tables});

  final String group;
  final List<DbTableSummary> tables;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      title: '$group (${tables.length})',
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // 카드 폭에 따라 2열 또는 1열. 설명이 한 줄에 담겨야 훑을 수 있습니다.
          final columns = constraints.maxWidth >= 900 ? 2 : 1;
          final width =
              (constraints.maxWidth - AppSpacing.lg * (columns - 1)) / columns;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Wrap(
              spacing: AppSpacing.lg,
              runSpacing: AppSpacing.sm,
              children: [
                for (final table in tables)
                  SizedBox(width: width, child: _TableRow(table: table)),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _TableRow extends StatefulWidget {
  const _TableRow({required this.table});

  final DbTableSummary table;

  @override
  State<_TableRow> createState() => _TableRowState();
}

class _TableRowState extends State<_TableRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final table = widget.table;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () => context.go(AppRoutes.dbTableOf(table.name)),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: _hovered ? AppColors.surfaceMuted : AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      // 설명이 먼저입니다. 이름만으로는 무엇을 담는지 알 수 없습니다.
                      table.comment == null
                          ? table.name
                          : table.comment!.split('.').first,
                      style: AppTypography.bodyStrong,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (table.containsPersonalData)
                    const Padding(
                      padding: EdgeInsets.only(left: AppSpacing.sm),
                      child: AppStatusChip(
                        label: '개인정보',
                        tone: StatusTone.caution,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Text(
                    table.name,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    '컬럼 ${table.columnCount}개'
                    '${table.estimatedRows == null ? "" : " / 약 ${Formats.count(table.estimatedRows)}행"}',
                    style: AppTypography.caption,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

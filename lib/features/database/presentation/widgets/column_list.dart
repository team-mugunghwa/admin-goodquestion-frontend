import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_data_table.dart';
import '../../../../core/widgets/app_page.dart';
import '../../../../core/widgets/app_status_chip.dart';
import '../../domain/entities/db_schema.dart';

/// 컬럼 목록. 이 화면의 핵심입니다.
///
/// 설명 열을 가장 넓게 잡았습니다. 타입과 제약은 개발자가 보는 것이고, 이 화면을
/// 여는 사람에게 필요한 것은 "이 컬럼이 무슨 값인가"입니다.
class ColumnList extends StatelessWidget {
  const ColumnList({required this.detail, super.key});

  final DbTableDetail detail;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppCard(
          title: '컬럼',
          padding: EdgeInsets.zero,
          child: AppDataTable<DbColumn>(
            items: detail.columns,
            rowKey: (column) => column.name,
            columns: [
              AppColumn(
                label: '컬럼',
                flex: 3,
                cellBuilder: (context, column) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            column.name,
                            style: AppTypography.bodyStrong,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (column.primaryKey)
                          const Padding(
                            padding: EdgeInsets.only(left: AppSpacing.xs),
                            child: AppStatusChip(
                              label: 'PK',
                              tone: StatusTone.info,
                            ),
                          ),
                      ],
                    ),
                    Text(column.type, style: AppTypography.caption),
                  ],
                ),
              ),
              AppColumn(
                label: '설명',
                flex: 6,
                cellBuilder: (context, column) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      column.comment ?? '설명이 없습니다',
                      style: column.comment == null
                          ? AppTypography.caption
                          : AppTypography.body,
                    ),
                    if (column.isForeignKey)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: InkWell(
                          onTap: () => context.go(
                            AppRoutes.dbTableOf(column.referencesTable!),
                          ),
                          child: Text(
                            // 어느 테이블과 이어지는지가 관계를 이해하는 실마리입니다.
                            '${column.referencesTable}.${column.referencesColumn} 을(를) 가리킵니다',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.primary,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              AppColumn(
                label: '필수',
                width: 60,
                cellBuilder: (context, column) => Text(
                  column.nullable ? '선택' : '필수',
                  style: AppTypography.caption.copyWith(
                    color: column.nullable ? AppColors.ink500 : AppColors.ink900,
                  ),
                ),
              ),
              AppColumn(
                label: '기본값',
                flex: 2,
                cellBuilder: (context, column) => Text(
                  _shortenDefault(column.defaultValue),
                  style: AppTypography.caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              AppColumn(
                label: '',
                width: 76,
                cellBuilder: (context, column) => column.masked
                    ? const AppStatusChip(
                        label: '값 가림',
                        tone: StatusTone.negative,
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        _ReferencedByCard(references: detail.referencedBy),
        const SizedBox(height: AppSpacing.lg),
        _IndexCard(indexes: detail.indexes),
      ],
    );
  }

  /// `nextval('...')` 이나 긴 함수 호출이 그대로 들어가면 표가 밀립니다.
  static String _shortenDefault(String? value) {
    if (value == null) return '-';
    if (value.length <= 28) return value;
    return '${value.substring(0, 28)}...';
  }
}

/// 이 테이블을 가리키는 곳.
///
/// 컬럼의 외래키는 "내가 어디를 보는가"만 알려 줍니다. 값을 지워도 되는지,
/// 이 테이블이 어디에 쓰이는지 알려면 반대 방향이 필요합니다.
class _ReferencedByCard extends StatelessWidget {
  const _ReferencedByCard({required this.references});

  final List<DbIncomingReference> references;

  @override
  Widget build(BuildContext context) {
    if (references.isEmpty) {
      return AppCard(
        title: '이 테이블을 가리키는 곳',
        child: Text('없습니다. 다른 테이블이 이 테이블을 참조하지 않습니다.',
            style: AppTypography.caption),
      );
    }
    return AppCard(
      title: '이 테이블을 가리키는 곳 (${references.length})',
      trailing: TextButton.icon(
        onPressed: () => context.go(AppRoutes.dbDiagram),
        icon: const Icon(AppIcons.diagram, size: AppSizes.icon),
        label: const Text('관계도에서 보기'),
      ),
      child: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: [
          for (final reference in references)
            InkWell(
              onTap: () => context.go(AppRoutes.dbTableOf(reference.table)),
              borderRadius: BorderRadius.circular(AppRadius.sm),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Text(
                  '${reference.table}.${reference.column}',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _IndexCard extends StatelessWidget {
  const _IndexCard({required this.indexes});

  final List<DbIndex> indexes;

  @override
  Widget build(BuildContext context) {
    if (indexes.isEmpty) {
      return AppCard(
        title: '인덱스',
        child: Text('인덱스가 없습니다.', style: AppTypography.caption),
      );
    }
    return AppCard(
      title: '인덱스',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '같은 값을 두 번 넣지 못하게 막거나(고유), 찾는 속도를 높이려고 걸어 둔 것입니다.',
            style: AppTypography.caption,
          ),
          const SizedBox(height: AppSpacing.md),
          for (final index in indexes)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 76,
                    child: index.primaryKey
                        ? const AppStatusChip(label: '기본키', tone: StatusTone.info)
                        : index.unique
                        ? const AppStatusChip(label: '고유', tone: StatusTone.positive)
                        : const AppStatusChip(label: '검색용', tone: StatusTone.neutral),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(index.name, style: AppTypography.body),
                        Text(index.definition, style: AppTypography.caption),
                      ],
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

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import 'schema_layout.dart';

/// 관계도의 상자 하나.
///
/// 설명을 크게, 테이블 이름을 작게 적습니다. 목록 화면과 같은 규칙입니다.
/// 아래에는 기본키와 외래키만 적습니다. 컬럼을 다 적으면 상자가 화면을 덮습니다.
class TableBox extends StatelessWidget {
  const TableBox({
    required this.placed,
    required this.focused,
    required this.onTap,
    super.key,
  });

  final PlacedTable placed;
  final bool focused;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final muted = placed.dimmed && !focused;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.md),
            // 테두리 두께는 눌렀을 때도 그대로 둡니다. 두꺼워지면 안쪽 높이가
            // 줄어 배치와 어긋나고, 상자가 미세하게 떨립니다. 강조는 색으로 합니다.
            border: Border.all(
              color: focused ? AppColors.primary : AppColors.ink100,
              width: SchemaLayout.borderWidth,
            ),
            boxShadow: muted ? null : AppColors.cardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Header(placed: placed, focused: focused, muted: muted),
              for (final key in placed.visibleKeyColumns)
                _KeyRow(name: key.name, primary: key.primaryKey,
                    foreign: key.foreignKey, muted: muted),
              if (placed.hiddenKeyCount > 0)
                _KeyRow(
                  name: '키 ${placed.hiddenKeyCount}개 더',
                  primary: false,
                  foreign: false,
                  muted: true,
                ),
              const SizedBox(height: AppSpacing.sm),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.placed,
    required this.focused,
    required this.muted,
  });

  final PlacedTable placed;
  final bool focused;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: SchemaLayout.headerHeight,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: focused ? AppColors.primarySurface : AppColors.surfaceMuted,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.md - 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  placed.node.title,
                  style: AppTypography.bodyStrong.copyWith(
                    color: muted ? AppColors.ink500 : AppColors.ink900,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (placed.node.containsPersonalData)
                Icon(
                  Icons.privacy_tip_rounded,
                  size: 13,
                  color: muted ? AppColors.ink400 : AppColors.warning,
                ),
            ],
          ),
          Text(
            placed.name,
            style: AppTypography.caption.copyWith(
              color: muted ? AppColors.ink400 : AppColors.primary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _KeyRow extends StatelessWidget {
  const _KeyRow({
    required this.name,
    required this.primary,
    required this.foreign,
    required this.muted,
  });

  final String name;
  final bool primary;
  final bool foreign;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    // PK / FK 는 색이 아니라 글자로 구분합니다. 흑백으로 뽑아도 읽혀야 합니다.
    final label = primary && foreign
        ? 'PK FK'
        : primary
        ? 'PK'
        : foreign
        ? 'FK'
        : '';

    return SizedBox(
      height: SchemaLayout.keyRowHeight,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        child: Row(
          children: [
            SizedBox(
              width: 34,
              child: Text(
                label,
                style: AppTypography.badge.copyWith(
                  fontSize: 9,
                  color: muted ? AppColors.ink400 : AppColors.ink500,
                ),
              ),
            ),
            Expanded(
              child: Text(
                name,
                style: AppTypography.caption.copyWith(
                  fontSize: 11,
                  color: muted ? AppColors.ink400 : AppColors.ink700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

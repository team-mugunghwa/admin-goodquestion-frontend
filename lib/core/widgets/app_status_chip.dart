import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// 상태 배지의 색 계열.
///
/// 뜻이 아니라 강도로 이름을 붙였습니다. "공개"가 어느 화면에서는 초록이고 다른
/// 화면에서는 파랑이 되는 것을 막으려면, 각 화면이 뜻을 이 네 단계 중 하나로
/// 번역하고 색은 여기서만 정해야 합니다.
enum StatusTone {
  /// 진행 중, 정보. 파랑.
  info,

  /// 정상, 완료. 초록.
  positive,

  /// 확인 필요. 주황.
  caution,

  /// 되돌릴 수 없는 것, 막힌 것. 빨강.
  negative,

  /// 비활성, 초안. 회색.
  neutral,
}

/// 상태 배지.
///
/// **색만으로 뜻을 전하지 않습니다.** 항상 글자가 함께 있고, 표를 흑백으로 뽑거나
/// 색각 이상이 있어도 읽힙니다.
class AppStatusChip extends StatelessWidget {
  const AppStatusChip({required this.label, required this.tone, super.key});

  final String label;
  final StatusTone tone;

  @override
  Widget build(BuildContext context) {
    final (background, foreground) = switch (tone) {
      StatusTone.info => (AppColors.primarySurface, AppColors.primary),
      StatusTone.positive => (AppColors.successSurface, AppColors.success),
      StatusTone.caution => (AppColors.warningSurface, AppColors.warning),
      StatusTone.negative => (AppColors.dangerSurface, AppColors.danger),
      StatusTone.neutral => (AppColors.surfaceMuted, AppColors.ink500),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        label,
        style: AppTypography.badge.copyWith(color: foreground),
      ),
    );
  }
}

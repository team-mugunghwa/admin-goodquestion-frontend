import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formats.dart';

/// 지표 한 칸.
///
/// 숫자 하나에 이름 하나, 그리고 필요하면 보조 설명 한 줄까지입니다. 화살표나
/// 증감률을 넣지 않은 이유: 어제 대비 증감은 표본이 작을 때 요동이 심해서
/// (사용자 100명 규모에서는 하루 3명 차이가 3%로 보입니다) 판단을 오히려 흐립니다.
/// 추세는 아래 방문자 그래프가 보여줍니다.
class StatCard extends StatelessWidget {
  const StatCard({
    required this.label,
    required this.value,
    this.hint,
    this.tone,
    this.onTap,
    super.key,
  });

  final String label;
  final int value;
  final String? hint;

  /// 강조가 필요한 지표의 색. 미답변 문의처럼 0이 아니면 조치가 필요한 값에 씁니다.
  final Color? tone;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    // 강조색을 지정했더라도 값이 0이면 평범하게 그립니다. 할 일이 없는데
    // 빨간 숫자가 떠 있으면 다음에 진짜 빨개졌을 때 눈에 안 들어옵니다.
    final emphasize = tone != null && value > 0;

    final card = Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.ink100),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: AppTypography.caption),
          const SizedBox(height: AppSpacing.sm),
          Text(
            Formats.count(value),
            style: AppTypography.metric.copyWith(
              color: emphasize ? tone : AppColors.ink900,
            ),
          ),
          if (hint != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(hint!, style: AppTypography.caption),
          ],
        ],
      ),
    );

    if (onTap == null) return card;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(onTap: onTap, child: card),
    );
  }
}

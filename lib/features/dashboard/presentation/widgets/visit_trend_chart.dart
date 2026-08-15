import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/dashboard_summary.dart';

/// 방문자 추이 막대 그래프.
///
/// **차트 라이브러리를 넣지 않았습니다.** 필요한 것은 막대 14개와 값 하나뿐인데,
/// 차트 패키지는 축·범례·애니메이션·인터랙션을 함께 가져오고 웹 번들이 그만큼
/// 커집니다. 이 정도는 `Column` 과 `Container` 로 충분합니다.
class VisitTrendChart extends StatelessWidget {
  const VisitTrendChart({required this.points, super.key});

  final List<DailyPoint> points;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return SizedBox(
        height: 160,
        child: Center(
          child: Text('표시할 기록이 없습니다', style: AppTypography.caption),
        ),
      );
    }

    // 최댓값이 0이면(2주 내내 방문 없음) 나누기에서 터집니다. 최소 1로 둡니다.
    final maxValue = points
        .map((point) => point.value)
        .fold<int>(1, (a, b) => a > b ? a : b);

    return SizedBox(
      height: 180,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final point in points)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: _Bar(
                  point: point,
                  ratio: point.value / maxValue,
                  // 오늘은 아직 진행 중인 날이라 다른 날과 같은 잣대로 볼 수 없습니다.
                  isToday: point == points.last,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.point, required this.ratio, required this.isToday});

  final DailyPoint point;
  final double ratio;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: '${point.date.month}월 ${point.date.day}일 · ${point.value}명',
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            '${point.value}',
            style: AppTypography.caption.copyWith(
              fontSize: 11,
              color: point.value == 0 ? AppColors.ink400 : AppColors.ink700,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          // 값이 0이어도 2px 은 남깁니다. 막대가 아예 없으면 그날이 x축에서
          // 사라진 것처럼 보입니다.
          FractionallySizedBox(
            widthFactor: 1,
            child: Container(
              height: 4 + ratio * 110,
              decoration: BoxDecoration(
                color: isToday ? AppColors.primary : AppColors.primarySurface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppRadius.sm),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '${point.date.day}',
            style: AppTypography.caption.copyWith(fontSize: 11),
          ),
        ],
      ),
    );
  }
}

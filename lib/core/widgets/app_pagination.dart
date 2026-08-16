import 'package:flutter/material.dart';

import '../constants/app_icons.dart';
import '../network/page_result.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../utils/formats.dart';

/// 페이지 이동 바.
///
/// 페이지 번호를 여러 개 늘어놓지 않고 "N / M" 과 이전/다음만 둡니다. 관리자
/// 목록은 대개 검색으로 좁혀서 보는 것이라, 7페이지로 바로 뛰는 일이 드뭅니다.
/// 번호를 늘어놓으면 총 페이지가 많을 때 말줄임 규칙까지 만들어야 합니다.
class AppPagination extends StatelessWidget {
  const AppPagination({
    required this.result,
    required this.onPageChanged,
    super.key,
  });

  final PageResult<Object?> result;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    // 한 페이지에 다 들어오면 이동할 곳이 없습니다.
    if (result.totalPages <= 1) {
      return Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Text(
          '전체 ${Formats.count(result.totalElements)}건',
          style: AppTypography.caption,
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.ink100)),
      ),
      child: Row(
        children: [
          Text(
            '전체 ${Formats.count(result.totalElements)}건',
            style: AppTypography.caption,
          ),
          const Spacer(),
          IconButton(
            tooltip: '이전',
            onPressed: result.hasPrevious
                ? () => onPageChanged(result.page - 1)
                : null,
            icon: const Icon(AppIcons.previousPage),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            // 사람이 읽는 번호는 1부터입니다. 0부터 세는 것은 서버와 맞추기 위한
            // 내부 규칙이라 화면에서는 이 한 곳에서만 바꿔 줍니다.
            child: Text(
              '${result.page + 1} / ${result.totalPages}',
              style: AppTypography.number,
            ),
          ),
          IconButton(
            tooltip: '다음',
            onPressed: result.hasNext
                ? () => onPageChanged(result.page + 1)
                : null,
            icon: const Icon(AppIcons.nextPage),
          ),
        ],
      ),
    );
  }
}

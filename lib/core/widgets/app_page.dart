import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../constants/app_icons.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// 콘텐츠 영역의 바깥틀. 제목 + 설명 + 우측 조작 + 본문.
///
/// 화면마다 제목 크기와 여백을 각자 정하면 메뉴를 옮길 때마다 본문이 미세하게
/// 위아래로 튑니다. 여기 한 곳에서 정합니다.
class AppPage extends StatelessWidget {
  const AppPage({
    required this.title,
    required this.child,
    this.description,
    this.actions = const [],
    this.backRoute,
    this.scrollable = true,
    super.key,
  });

  final String title;

  /// 제목 아래 한 줄. 이 화면에서 무엇을 하는지 모호할 때만 씁니다.
  final String? description;

  /// 우측 상단 버튼들. 주 조작(등록 등) 하나만 채운 버튼으로 두세요.
  final List<Widget> actions;

  /// 뒤로 갈 곳. 상세·편집 화면에서만 씁니다.
  ///
  /// 브라우저 뒤로 가기 대신 명시적인 버튼을 두는 이유: 목록에서 상세로 들어온
  /// 것인지 알림 링크로 바로 들어온 것인지에 따라 뒤로 가기의 결과가 달라집니다.
  final String? backRoute;

  /// 본문을 스크롤 가능하게 감쌀지. 표처럼 스스로 스크롤하는 본문은 `false`.
  final bool scrollable;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final header = Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.page,
        AppSpacing.xl,
        AppSpacing.page,
        AppSpacing.lg,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (backRoute != null) ...[
            IconButton(
              onPressed: () => context.go(backRoute!),
              icon: const Icon(AppIcons.back),
              tooltip: '목록으로',
              style: IconButton.styleFrom(foregroundColor: AppColors.ink700),
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.pageTitle),
                if (description != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(description!, style: AppTypography.caption),
                ],
              ],
            ),
          ),
          if (actions.isNotEmpty)
            Wrap(spacing: AppSpacing.sm, children: actions),
        ],
      ),
    );

    final body = Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.page,
        0,
        AppSpacing.page,
        AppSpacing.xxl,
      ),
      child: child,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        header,
        Expanded(
          child: scrollable ? SingleChildScrollView(child: body) : body,
        ),
      ],
    );
  }
}

/// 흰 카드. 표, 폼, 지표를 담는 기본 그릇.
class AppCard extends StatelessWidget {
  const AppCard({
    required this.child,
    this.title,
    this.trailing,
    this.padding = const EdgeInsets.all(AppSpacing.xl),
    super.key,
  });

  final String? title;
  final Widget? trailing;
  final EdgeInsets padding;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.ink100),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (title != null || trailing != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.lg,
                AppSpacing.lg,
                0,
              ),
              child: Row(
                children: [
                  if (title != null)
                    Expanded(
                      child: Text(title!, style: AppTypography.sectionTitle),
                    )
                  else
                    const Spacer(),
                  if (trailing != null) trailing!,
                ],
              ),
            ),
          Padding(padding: padding, child: child),
        ],
      ),
    );
  }
}

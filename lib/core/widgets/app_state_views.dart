import 'package:flutter/material.dart';

import '../constants/app_icons.dart';
import '../state/view_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// 로딩 / 오류 / 빈 상태를 한 방식으로 그립니다.
///
/// 화면마다 각자 만들면 어떤 화면은 스피너, 어떤 화면은 "불러오는 중..." 글자가
/// 나옵니다. 관리자 콘솔은 메뉴를 자주 오가므로 그 차이가 특히 눈에 띕니다.
class AppStateView extends StatelessWidget {
  const AppStateView({
    required this.state,
    required this.builder,
    this.onRetry,
    this.errorMessage,
    this.isEmpty = false,
    this.emptyTitle = '아직 없습니다',
    this.emptyDescription,
    this.emptyAction,
    super.key,
  });

  final ViewState state;
  final String? errorMessage;
  final VoidCallback? onRetry;

  /// 성공했지만 결과가 비었는지. 빈 표를 그리는 대신 안내를 보여줍니다.
  final bool isEmpty;
  final String emptyTitle;
  final String? emptyDescription;
  final Widget? emptyAction;

  final WidgetBuilder builder;

  @override
  Widget build(BuildContext context) {
    return switch (state) {
      ViewState.idle || ViewState.loading => const AppLoadingView(),
      ViewState.error => AppErrorView(message: errorMessage, onRetry: onRetry),
      ViewState.success =>
        isEmpty
            ? AppEmptyView(
                title: emptyTitle,
                description: emptyDescription,
                action: emptyAction,
              )
            : builder(context),
    };
  }
}

class AppLoadingView extends StatelessWidget {
  const AppLoadingView({this.height = 240, super.key});

  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: const Center(
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(strokeWidth: 3),
        ),
      ),
    );
  }
}

class AppErrorView extends StatelessWidget {
  const AppErrorView({this.message, this.onRetry, super.key});

  final String? message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return _CenteredMessage(
      icon: AppIcons.warning,
      iconColor: AppColors.danger,
      title: message ?? '불러오지 못했습니다',
      // 원인이 무엇이든 관리자가 할 수 있는 일은 다시 시도뿐입니다.
      action: onRetry == null
          ? null
          : OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(AppIcons.refresh, size: AppSizes.icon),
              label: const Text('다시 시도'),
            ),
    );
  }
}

class AppEmptyView extends StatelessWidget {
  const AppEmptyView({
    required this.title,
    this.description,
    this.action,
    super.key,
  });

  final String title;
  final String? description;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return _CenteredMessage(
      icon: AppIcons.empty,
      iconColor: AppColors.ink400,
      title: title,
      description: description,
      action: action,
    );
  }
}

class _CenteredMessage extends StatelessWidget {
  const _CenteredMessage({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.description,
    this.action,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String? description;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxxl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 40, color: iconColor),
          const SizedBox(height: AppSpacing.lg),
          Text(title, style: AppTypography.bodyStrong, textAlign: TextAlign.center),
          if (description != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              description!,
              style: AppTypography.caption,
              textAlign: TextAlign.center,
            ),
          ],
          if (action != null) ...[
            const SizedBox(height: AppSpacing.xl),
            action!,
          ],
        ],
      ),
    );
  }
}

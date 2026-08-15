import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

/// 앱 테마.
///
/// **위젯 안에서 색을 직접 쓰지 마세요.** `Colors.blue` 대신 `AppColors` 또는
/// `Theme.of(context).colorScheme` 을 씁니다.
///
/// ## 다크 모드는 만들지 않습니다
///
/// 관리자 콘솔은 표와 상태 배지가 화면의 대부분입니다. 배지 색을 두 벌 유지하면서
/// 대비를 검수할 여력이 없고, 운영자 몇 명이 낮에 보는 화면이라 얻는 것도 적습니다.
abstract final class AppTheme {
  static ThemeData get light => _build();

  static ThemeData _build() {
    final scheme = ColorScheme.fromSeed(seedColor: AppColors.primary).copyWith(
      primary: AppColors.primary,
      onPrimary: AppColors.surface,
      primaryContainer: AppColors.primarySurface,
      onPrimaryContainer: AppColors.ink900,
      surface: AppColors.surface,
      onSurface: AppColors.ink900,
      onSurfaceVariant: AppColors.ink500,
      surfaceContainerLowest: AppColors.surface,
      surfaceContainer: AppColors.canvas,
      surfaceContainerHighest: AppColors.surfaceMuted,
      error: AppColors.danger,
      onError: AppColors.surface,
      outline: AppColors.ink300,
      outlineVariant: AppColors.ink100,
    );

    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
      borderSide: const BorderSide(color: AppColors.ink300),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      textTheme: AppTypography.textTheme,
      scaffoldBackgroundColor: AppColors.canvas,
      dividerColor: AppColors.ink100,
      focusColor: AppColors.primary,
      splashFactory: InkSparkle.splashFactory,

      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppColors.ink900,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: AppTypography.sectionTitle,
      ),

      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.surface,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: const BorderSide(color: AppColors.ink100),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, AppSizes.tapTarget),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          textStyle: AppTypography.bodyStrong,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, AppSizes.tapTarget),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          foregroundColor: AppColors.ink700,
          side: const BorderSide(color: AppColors.ink300),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          textStyle: AppTypography.bodyStrong,
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(0, AppSizes.tapTarget),
          foregroundColor: AppColors.primary,
          textStyle: AppTypography.bodyStrong,
        ),
      ),

      inputDecorationTheme: InputDecorationThemeData(
        filled: true,
        fillColor: AppColors.surface,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        border: border,
        enabledBorder: border,
        focusedBorder: border.copyWith(
          borderSide: const BorderSide(color: AppColors.primary, width: 1.6),
        ),
        errorBorder: border.copyWith(
          borderSide: const BorderSide(color: AppColors.danger),
        ),
        focusedErrorBorder: border.copyWith(
          borderSide: const BorderSide(color: AppColors.danger, width: 1.6),
        ),
        hintStyle: AppTypography.body.copyWith(color: AppColors.ink400),
        labelStyle: AppTypography.body.copyWith(color: AppColors.ink500),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        titleTextStyle: AppTypography.sectionTitle,
        contentTextStyle: AppTypography.body,
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.ink900,
        contentTextStyle: AppTypography.body.copyWith(color: AppColors.surface),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceMuted,
        side: BorderSide.none,
        labelStyle: AppTypography.badge,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      ),

      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: AppColors.ink900,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        textStyle: AppTypography.caption.copyWith(color: AppColors.surface),
      ),
    );
  }
}

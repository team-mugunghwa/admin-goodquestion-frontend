import 'package:flutter/material.dart';

import 'app_colors.dart';

/// 글자 토큰.
///
/// **폰트를 번들하지 않습니다.** 서비스 앱은 나눔스퀘어라운드와 Pretendard 두 벌을
/// 싣지만, 관리자 콘솔은 운영자 몇 명이 데스크톱 브라우저로만 보는 화면입니다.
/// 폰트 파일 두 개를 받아 오느라 첫 화면이 늦어지는 대가가 얻는 것보다 큽니다.
/// 대신 시스템 폰트 스택을 지정해 macOS/Windows 어느 쪽에서도 한글이 또렷하게
/// 나오도록 합니다.
abstract final class AppTypography {
  /// OS 기본 한글 폰트를 순서대로 시도합니다. 마지막은 Flutter 기본값입니다.
  static const List<String> fontFallback = [
    'Pretendard',        // 설치돼 있으면 서비스 앱과 같은 글자가 됩니다
    'Apple SD Gothic Neo',
    'Malgun Gothic',
    'Noto Sans KR',
    'sans-serif',
  ];

  static const TextStyle _base = TextStyle(
    fontFamilyFallback: fontFallback,
    color: AppColors.ink900,
    height: 1.45,
  );

  /// 화면 제목. 페이지마다 한 번.
  static final TextStyle pageTitle = _base.copyWith(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 1.3,
  );

  /// 카드 제목, 섹션 제목.
  static final TextStyle sectionTitle = _base.copyWith(
    fontSize: 16,
    fontWeight: FontWeight.w700,
  );

  /// 대시보드 지표 숫자. 자릿수가 많아도 한눈에 들어와야 합니다.
  static final TextStyle metric = _base.copyWith(
    fontSize: 30,
    fontWeight: FontWeight.w700,
    height: 1.15,
    // 숫자가 표에서 자리마다 흔들리지 않게 고정폭 숫자를 씁니다.
    fontFeatures: const [FontFeature.tabularFigures()],
  );

  static final TextStyle body = _base.copyWith(fontSize: 14);

  static final TextStyle bodyStrong = _base.copyWith(
    fontSize: 14,
    fontWeight: FontWeight.w600,
  );

  /// 표 헤더.
  static final TextStyle tableHeader = _base.copyWith(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.ink500,
    letterSpacing: 0.2,
  );

  /// 캡션, 보조 설명, 표의 날짜 열.
  static final TextStyle caption = _base.copyWith(
    fontSize: 12,
    color: AppColors.ink500,
  );

  /// 배지 안의 글자.
  static final TextStyle badge = _base.copyWith(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    height: 1.2,
  );

  /// 숫자 열 전용. 자릿수가 흔들리면 표가 지저분해 보입니다.
  static final TextStyle number = _base.copyWith(
    fontSize: 14,
    fontFeatures: const [FontFeature.tabularFigures()],
  );

  static TextTheme get textTheme => TextTheme(
    headlineMedium: pageTitle,
    titleMedium: sectionTitle,
    bodyMedium: body,
    bodySmall: caption,
    labelLarge: bodyStrong,
    labelSmall: tableHeader,
  );
}

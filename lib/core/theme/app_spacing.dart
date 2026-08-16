/// 간격 토큰. 4의 배수로 통일합니다.
///
/// 위젯에 `EdgeInsets.all(13)` 같은 임의의 숫자를 쓰지 마세요. 화면마다 여백이
/// 미묘하게 달라지고, 표가 많은 화면에서는 그 차이가 눈에 잘 띕니다.
abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;

  /// 콘텐츠 영역의 좌우 여백.
  static const double page = xxl;
}

/// 모서리 둥글기.
///
/// **한 화면에서 2종류를 넘기지 마세요.** 카드와 입력이 다른 반경을 쓰면
/// 표 안에서 특히 지저분해 보입니다.
abstract final class AppRadius {
  static const double sm = 6;

  /// 입력, 버튼, 배지.
  static const double md = 10;

  /// 카드, 대화상자.
  static const double lg = 14;

  static const double pill = 999;
}

/// 고정 크기.
abstract final class AppSizes {
  /// 좌측 내비게이션 폭. 메뉴 이름이 두 줄로 접히지 않는 최소 폭입니다.
  static const double navWidth = 240;

  /// 상단 바 높이.
  static const double topBarHeight = 64;

  /// 최소 터치/클릭 타겟.
  static const double tapTarget = 40;

  /// 표 한 행의 높이. 너무 좁으면 스캔이 어렵고 너무 넓으면 한 화면에 덜 들어옵니다.
  static const double tableRowHeight = 52;

  /// 본문 콘텐츠 최대 폭. 편집 폼처럼 한 줄이 길면 읽기 힘든 화면에 씁니다.
  /// 표는 이 제한을 받지 않습니다 - 열이 많으면 넓을수록 좋습니다.
  static const double formMaxWidth = 720;

  /// 아이콘.
  static const double icon = 20;
  static const double iconLarge = 24;
}

import 'package:flutter/material.dart';

/// 색 토큰.
///
/// 서비스 앱과 <b>같은 브랜드 색에서 출발하되 쓰임이 다릅니다.</b> 서비스 앱은 아이가
/// 보는 화면이라 파스텔 면이 넓게 깔리지만, 관리자 콘솔은 표와 숫자를 오래 들여다보는
/// 화면입니다. 색이 넓게 깔리면 정작 봐야 할 상태 배지와 숫자가 묻힙니다.
///
/// ## 이 팔레트의 규칙 3가지
///
/// 1. **면은 흰색과 회색뿐입니다.** 브랜드 색은 주 버튼, 선택된 메뉴, 링크에만 씁니다.
/// 2. **상태는 색 하나로 말하지 않습니다.** 배지에는 색과 글자를 함께 둡니다 —
///    표를 흑백으로 출력하거나 색각 이상이 있어도 읽혀야 합니다.
/// 3. **빨강은 되돌릴 수 없는 것에만.** 삭제, 정지, 미답변 경고. 그 외에는 쓰지 않습니다.
abstract final class AppColors {
  // ─────────────────────────────────────────────────────────
  // 브랜드 — 서비스 앱과 같은 값
  // ─────────────────────────────────────────────────────────

  /// 주 색상. 주 버튼, 선택된 메뉴, 포커스 링. 흰 배경 대비 5.5:1.
  static const Color primary = Color(0xFF2A6E9E);

  /// 주 색상의 옅은 면. 선택된 행, 정보 배너.
  static const Color primarySurface = Color(0xFFEAF3F9);

  /// 성공·완료. 흰 배경 대비 5.1:1.
  static const Color success = Color(0xFF387C4C);
  static const Color successSurface = Color(0xFFE8F3EA);

  /// 확인 필요. 미답변 문의, 초안 상태.
  static const Color warning = Color(0xFF9A6412);
  static const Color warningSurface = Color(0xFFFBF0DC);

  /// 되돌릴 수 없는 것. 삭제, 정지.
  static const Color danger = Color(0xFFB3403C);
  static const Color dangerSurface = Color(0xFFFAEAEA);

  // ─────────────────────────────────────────────────────────
  // 잉크 — 글자·선
  // ─────────────────────────────────────────────────────────

  /// 본문. 순수 검정 대신 파랑기가 도는 남색이라 회색 배경에서 덜 딱딱합니다.
  static const Color ink900 = Color(0xFF16233F);

  /// 부제·표 헤더.
  static const Color ink700 = Color(0xFF33456B);

  /// 캡션·보조 설명. 흰 배경 대비 4.6:1이라 본문으로도 쓸 수 있습니다.
  static const Color ink500 = Color(0xFF5A6A8A);

  /// 비활성 글자·플레이스홀더.
  static const Color ink400 = Color(0xFF8C99B3);

  /// 입력 테두리.
  static const Color ink300 = Color(0xFFC2CCDB);

  /// 구분선·카드 테두리.
  static const Color ink100 = Color(0xFFE4E9F2);

  // ─────────────────────────────────────────────────────────
  // 바탕
  // ─────────────────────────────────────────────────────────

  /// 화면 바탕. 카드가 떠 보이도록 흰색보다 한 단계 어둡습니다.
  static const Color canvas = Color(0xFFF6F8FA);

  /// 카드·표·시트.
  static const Color surface = Color(0xFFFFFFFF);

  /// 표 헤더, 호버 행.
  static const Color surfaceMuted = Color(0xFFF0F3F7);

  /// 좌측 내비게이션. 화면에서 유일하게 어두운 면입니다 — 콘텐츠 영역과
  /// 경계를 확실히 나눠서, 폭이 넓은 모니터에서도 눈이 길을 잃지 않게 합니다.
  static const Color navSurface = Color(0xFF16233F);
  static const Color navSelected = Color(0xFF2A3B5E);
  static const Color navLabel = Color(0xFFB6C2D9);

  /// 카드 그림자. 검정 대신 잉크색을 옅게 깔아야 회색 때처럼 보이지 않습니다.
  static const List<BoxShadow> cardShadow = [
    BoxShadow(color: Color(0x0A16233F), blurRadius: 2, offset: Offset(0, 1)),
    BoxShadow(color: Color(0x0F16233F), blurRadius: 12, offset: Offset(0, 4)),
  ];
}

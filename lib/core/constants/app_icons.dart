import 'package:flutter/material.dart';

/// 아이콘 토큰.
///
/// **Flutter 내장 Material 아이콘의 `_rounded` 변형만 씁니다.** 아이콘 패키지를
/// 추가하지 않습니다 - 내장 세트로 충분하고, 섞으면 굵기와 광학 크기가 어긋납니다.
///
/// 화면에서 `Icons.article_rounded` 를 직접 쓰지 말고 여기 이름을 쓰세요.
/// "공지"의 아이콘을 바꿀 때 한 줄만 고치면 됩니다.
abstract final class AppIcons {
  // 메뉴
  static const IconData dashboard = Icons.dashboard_rounded;
  static const IconData story = Icons.auto_stories_rounded;
  static const IconData member = Icons.people_alt_rounded;
  static const IconData notice = Icons.campaign_rounded;
  static const IconData inquiry = Icons.support_agent_rounded;
  static const IconData guide = Icons.menu_book_rounded;
  static const IconData admin = Icons.admin_panel_settings_rounded;
  static const IconData auditLog = Icons.history_rounded;
  static const IconData database = Icons.storage_rounded;

  // 조작
  static const IconData add = Icons.add_rounded;
  static const IconData edit = Icons.edit_rounded;
  static const IconData delete = Icons.delete_outline_rounded;
  static const IconData search = Icons.search_rounded;
  static const IconData refresh = Icons.refresh_rounded;
  static const IconData save = Icons.check_rounded;
  static const IconData close = Icons.close_rounded;
  static const IconData back = Icons.arrow_back_rounded;
  static const IconData more = Icons.more_horiz_rounded;
  static const IconData dragHandle = Icons.drag_indicator_rounded;
  static const IconData logout = Icons.logout_rounded;

  // 페이지네이션
  static const IconData previousPage = Icons.chevron_left_rounded;
  static const IconData nextPage = Icons.chevron_right_rounded;

  // 상태
  static const IconData warning = Icons.error_outline_rounded;
  static const IconData empty = Icons.inbox_rounded;
  static const IconData success = Icons.check_circle_rounded;
  static const IconData suspended = Icons.block_rounded;
  static const IconData locked = Icons.lock_rounded;
}

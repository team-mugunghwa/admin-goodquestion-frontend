/// 앱의 모든 경로를 한 곳에 모아 둔 곳.
///
/// 화면에서 이동할 때 문자열을 직접 쓰지 마세요. 오타가 나도 컴파일러가 잡아 주지
/// 못하고, 경로가 바뀌면 전부 찾아 고쳐야 합니다.
///
/// ```dart
/// context.go(AppRoutes.notices);
/// context.go(AppRoutes.noticeDetailOf(id));
/// ```
///
/// `*Path` 상수는 go_router 에 등록할 때 쓰는 **템플릿**(`:id` 포함)이고,
/// `*Of()` 는 실제 이동에 쓰는 **완성된 경로**입니다.
abstract final class AppRoutes {
  /// 로그인. 셸(좌측 메뉴) 바깥에 있는 유일한 화면입니다.
  static const String login = '/login';

  /// 대시보드.
  static const String dashboard = '/';

  static const String stories = '/stories';
  static const String storyNew = '/stories/new';
  static const String storyDetailPath = '/stories/:storyId';

  static const String members = '/members';
  static const String memberDetailPath = '/members/:parentId';

  static const String notices = '/notices';
  static const String noticeNew = '/notices/new';
  static const String noticeDetailPath = '/notices/:noticeId';

  static const String inquiries = '/inquiries';
  static const String inquiryDetailPath = '/inquiries/:inquiryId';

  static const String guides = '/guides';

  /// 관리자 계정 관리. 최고관리자만 보입니다.
  static const String admins = '/admins';

  /// 감사 로그.
  static const String auditLogs = '/audit-logs';

  /// 데이터베이스 둘러보기. 읽기 전용이라 하위 경로에 편집 화면이 없습니다.
  static const String database = '/database';
  static const String dbTablePath = '/database/:tableName';

  /// 내 계정(비밀번호 변경).
  static const String account = '/account';

  /// 경로 파라미터 이름. `state.pathParameters[AppRoutes.storyIdParam]`
  static const String storyIdParam = 'storyId';
  static const String parentIdParam = 'parentId';
  static const String noticeIdParam = 'noticeId';
  static const String inquiryIdParam = 'inquiryId';
  static const String tableNameParam = 'tableName';

  static String storyDetailOf(String storyId) => '/stories/$storyId';
  static String memberDetailOf(String parentId) => '/members/$parentId';
  static String noticeDetailOf(String noticeId) => '/notices/$noticeId';
  static String inquiryDetailOf(String inquiryId) => '/inquiries/$inquiryId';
  static String dbTableOf(String tableName) => '/database/$tableName';

  /// 로그인 후 돌아갈 곳을 실어 보내는 쿼리 파라미터 이름.
  ///
  /// 토큰이 만료된 채로 문의 상세 링크를 열면 로그인 화면이 뜨는데, 로그인 후에
  /// 대시보드로 보내면 열려던 문의를 다시 찾아가야 합니다.
  static const String redirectParam = 'redirect';

  static String loginWithRedirect(String location) =>
      '$login?$redirectParam=${Uri.encodeComponent(location)}';
}

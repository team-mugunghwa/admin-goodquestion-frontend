import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../features/audit/presentation/views/audit_log_view.dart';
import '../../features/auth/presentation/viewmodels/admin_session.dart';
import '../../features/auth/presentation/views/admin_account_view.dart';
import '../../features/auth/presentation/views/login_view.dart';
import '../../features/auth/presentation/views/my_account_view.dart';
import '../../features/dashboard/presentation/views/dashboard_view.dart';
import '../../features/database/presentation/views/database_list_view.dart';
import '../../features/database/presentation/views/schema_diagram_view.dart';
import '../../features/database/presentation/views/table_detail_view.dart';
import '../../features/guide/presentation/views/guide_list_view.dart';
import '../../features/member/presentation/views/member_detail_view.dart';
import '../../features/member/presentation/views/member_list_view.dart';
import '../../features/notice/presentation/views/notice_edit_view.dart';
import '../../features/notice/presentation/views/notice_list_view.dart';
import '../../features/story/presentation/views/story_edit_view.dart';
import '../../features/story/presentation/views/story_list_view.dart';
import '../../features/support/presentation/views/inquiry_detail_view.dart';
import '../../features/support/presentation/views/inquiry_list_view.dart';
import '../widgets/admin_shell.dart';
import 'app_routes.dart';

/// go_router 설정.
///
/// **로그인 여부 판단은 여기 [redirect] 한 곳에만 둡니다.** 화면마다 검사하면
/// 반드시 어딘가 빠뜨리고, 그 화면은 로그인 없이 열립니다.
GoRouter createRouter(AdminSession session) {
  return GoRouter(
    initialLocation: AppRoutes.dashboard,
    // 세션이 바뀌면 라우터가 redirect 를 다시 평가합니다. 로그아웃하는 순간
    // 보고 있던 화면에서 로그인 화면으로 밀려납니다.
    refreshListenable: session,
    redirect: (context, state) {
      // 토큰 복구가 끝나기 전에는 판단하지 않습니다. 여기서 로그인 화면으로 보내면
      // 새로고침할 때마다 로그인 화면이 한 번 스쳤다가 사라집니다.
      if (session.isRestoring) return null;

      final loggingIn = state.matchedLocation == AppRoutes.login;
      if (!session.isSignedIn) {
        // 열려던 주소를 실어 보냅니다. 로그인 후 그리로 돌아갑니다.
        return loggingIn
            ? null
            : AppRoutes.loginWithRedirect(state.uri.toString());
      }
      if (loggingIn) {
        final redirect = state.uri.queryParameters[AppRoutes.redirectParam];
        return redirect == null || redirect.isEmpty
            ? AppRoutes.dashboard
            : redirect;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginView(),
      ),

      // 나머지는 전부 셸(좌측 메뉴 + 상단 바) 안에서 그립니다.
      // ShellRoute 를 쓰면 메뉴 사이를 오갈 때 셸이 다시 만들어지지 않습니다.
      ShellRoute(
        builder: (context, state, child) =>
            AdminShell(location: state.uri.path, child: child),
        routes: [
          GoRoute(
            path: AppRoutes.dashboard,
            builder: (context, state) => const DashboardView(),
          ),
          GoRoute(
            path: AppRoutes.stories,
            builder: (context, state) => const StoryListView(),
            routes: [
              // 'new' 를 :storyId 보다 먼저 등록해야 합니다. 순서가 반대면
              // /stories/new 가 storyId="new" 로 잡힙니다.
              GoRoute(
                path: 'new',
                builder: (context, state) => const StoryEditView(),
              ),
              GoRoute(
                path: ':${AppRoutes.storyIdParam}',
                builder: (context, state) => StoryEditView(
                  storyId: state.pathParameters[AppRoutes.storyIdParam],
                ),
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.members,
            builder: (context, state) => const MemberListView(),
            routes: [
              GoRoute(
                path: ':${AppRoutes.parentIdParam}',
                builder: (context, state) => MemberDetailView(
                  parentId: state.pathParameters[AppRoutes.parentIdParam]!,
                ),
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.notices,
            builder: (context, state) => const NoticeListView(),
            routes: [
              GoRoute(
                path: 'new',
                builder: (context, state) => const NoticeEditView(),
              ),
              GoRoute(
                path: ':${AppRoutes.noticeIdParam}',
                builder: (context, state) => NoticeEditView(
                  noticeId: state.pathParameters[AppRoutes.noticeIdParam],
                ),
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.inquiries,
            builder: (context, state) => const InquiryListView(),
            routes: [
              GoRoute(
                path: ':${AppRoutes.inquiryIdParam}',
                builder: (context, state) => InquiryDetailView(
                  inquiryId: state.pathParameters[AppRoutes.inquiryIdParam]!,
                ),
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.guides,
            builder: (context, state) => const GuideListView(),
          ),
          GoRoute(
            path: AppRoutes.admins,
            builder: (context, state) => const AdminAccountView(),
          ),
          GoRoute(
            path: AppRoutes.auditLogs,
            builder: (context, state) => const AuditLogView(),
          ),
          GoRoute(
            path: AppRoutes.database,
            builder: (context, state) => const DatabaseListView(),
            routes: [
              // 'diagram' 을 :tableName 보다 먼저 등록해야 합니다. 순서가 반대면
              // /database/diagram 이 tableName="diagram" 으로 잡힙니다.
              GoRoute(
                path: 'diagram',
                builder: (context, state) => const SchemaDiagramView(),
              ),
              GoRoute(
                path: ':${AppRoutes.tableNameParam}',
                builder: (context, state) => TableDetailView(
                  tableName: state.pathParameters[AppRoutes.tableNameParam]!,
                ),
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.account,
            builder: (context, state) => const MyAccountView(),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => _RouteNotFoundView(location: state.uri.path),
  );
}

class _RouteNotFoundView extends StatelessWidget {
  const _RouteNotFoundView({required this.location});

  final String location;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('없는 주소입니다', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(location, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => context.go(AppRoutes.dashboard),
              child: const Text('대시보드로'),
            ),
          ],
        ),
      ),
    );
  }
}

/// `context.read<AdminSession>()` 를 라우터에서 쓰기 위한 확장.
///
/// 라우터가 만들어지는 시점에는 위젯 트리가 없어서 [createRouter] 가 세션을
/// 직접 받습니다. 이 확장은 화면 쪽에서 쓰는 편의 함수입니다.
extension AdminSessionContext on BuildContext {
  AdminSession get session => read<AdminSession>();
}

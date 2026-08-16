import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../features/auth/presentation/viewmodels/admin_session.dart';
import '../constants/app_icons.dart';
import '../router/app_routes.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// 로그인 이후 모든 화면을 감싸는 껍데기. 좌측 메뉴 + 상단 바.
///
/// `ShellRoute` 안에서 만들어지므로 메뉴 사이를 오갈 때 다시 만들어지지 않습니다.
/// 그래서 스크롤 위치와 포커스가 유지됩니다.
class AdminShell extends StatelessWidget {
  const AdminShell({required this.location, required this.child, super.key});

  /// 현재 경로. 어느 메뉴를 선택 상태로 그릴지 정하는 데 씁니다.
  final String location;
  final Widget child;

  /// 좌측 메뉴를 접는 기준 폭.
  ///
  /// 관리자 콘솔은 데스크톱 전용이지만 노트북 화면이나 창을 반으로 나눠 쓰는 경우가
  /// 있습니다. 240px 메뉴가 그대로 있으면 표의 열이 잘리므로, 좁아지면 아이콘만 남깁니다.
  static const double _collapseWidth = 1100;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final collapsed = constraints.maxWidth < _collapseWidth;
        return Scaffold(
          body: Row(
            children: [
              _SideNav(location: location, collapsed: collapsed),
              Expanded(
                child: Column(
                  children: [
                    const _TopBar(),
                    Expanded(child: child),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _NavItem {
  const _NavItem(this.route, this.icon, this.label, {this.superAdminOnly = false});

  final String route;
  final IconData icon;
  final String label;

  /// 최고관리자에게만 보이는 메뉴. 권한이 없으면 목록에서 아예 뺍니다 -
  /// 눌러도 403 이 나는 메뉴를 보여 줄 이유가 없습니다.
  final bool superAdminOnly;
}

const List<_NavItem> _navItems = [
  _NavItem(AppRoutes.dashboard, AppIcons.dashboard, '대시보드'),
  _NavItem(AppRoutes.stories, AppIcons.story, '이야기 관리'),
  _NavItem(AppRoutes.members, AppIcons.member, '사용자 관리'),
  _NavItem(AppRoutes.notices, AppIcons.notice, '공지사항 관리'),
  _NavItem(AppRoutes.inquiries, AppIcons.inquiry, '고객센터'),
  _NavItem(AppRoutes.guides, AppIcons.guide, '이용안내 관리'),
  _NavItem(AppRoutes.database, AppIcons.database, '데이터베이스'),
  _NavItem(AppRoutes.admins, AppIcons.admin, '관리자 계정', superAdminOnly: true),
  _NavItem(AppRoutes.auditLogs, AppIcons.auditLog, '감사 로그'),
];

class _SideNav extends StatelessWidget {
  const _SideNav({required this.location, required this.collapsed});

  final String location;
  final bool collapsed;

  @override
  Widget build(BuildContext context) {
    final role = context.watch<AdminSession>().admin?.role;
    final items = _navItems
        .where((item) => !item.superAdminOnly || (role?.canManageAdmins ?? false))
        .toList();

    return Container(
      width: collapsed ? 72 : AppSizes.navWidth,
      color: AppColors.navSurface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Brand(collapsed: collapsed),
          const SizedBox(height: AppSpacing.sm),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return _NavTile(
                  item: item,
                  collapsed: collapsed,
                  selected: _isSelected(item.route),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// 대시보드는 정확히 일치할 때만 선택입니다. `/` 로 startsWith 를 쓰면
  /// 모든 경로가 대시보드로 잡힙니다.
  bool _isSelected(String route) {
    if (route == AppRoutes.dashboard) return location == AppRoutes.dashboard;
    return location == route || location.startsWith('$route/');
  }
}

class _Brand extends StatelessWidget {
  const _Brand({required this.collapsed});

  final bool collapsed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            alignment: Alignment.center,
            child: Text(
              'Q',
              style: AppTypography.bodyStrong.copyWith(
                color: AppColors.surface,
                fontSize: 16,
              ),
            ),
          ),
          if (!collapsed) ...[
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                '굿퀘스천 관리자',
                style: AppTypography.bodyStrong.copyWith(
                  color: AppColors.surface,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.item,
    required this.collapsed,
    required this.selected,
  });

  final _NavItem item;
  final bool collapsed;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final tile = Material(
      color: selected ? AppColors.navSelected : Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        onTap: () => context.go(item.route),
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: collapsed ? AppSpacing.md : AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          child: Row(
            mainAxisAlignment: collapsed
                ? MainAxisAlignment.center
                : MainAxisAlignment.start,
            children: [
              Icon(
                item.icon,
                size: AppSizes.icon,
                // 선택 여부를 색만으로 구분하지 않습니다. 배경 면도 함께 바뀝니다.
                // 선택된 항목에는 브랜드 하늘색을 씁니다. 어두운 면 위에서만
                // 쓸 수 있는 색이라(흰 배경 대비 2.2:1) 여기가 제자리입니다.
                color: selected ? AppColors.primaryOnDark : AppColors.navLabel,
              ),
              if (!collapsed) ...[
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    item.label,
                    style: AppTypography.body.copyWith(
                      color: selected ? AppColors.surface : AppColors.navLabel,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      // 접힌 상태에서는 글자가 없으므로 툴팁이 유일한 이름입니다.
      child: collapsed ? Tooltip(message: item.label, child: tile) : tile,
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    final session = context.watch<AdminSession>();
    final admin = session.admin;

    return Container(
      height: AppSizes.topBarHeight,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.ink100)),
      ),
      child: Row(
        children: [
          const Spacer(),
          if (admin != null)
            PopupMenuButton<String>(
              tooltip: '계정 메뉴',
              position: PopupMenuPosition.under,
              onSelected: (value) async {
                if (value == 'account') {
                  context.go(AppRoutes.account);
                } else if (value == 'logout') {
                  await context.read<AdminSession>().signOut();
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'account', child: Text('비밀번호 변경')),
                PopupMenuItem(value: 'logout', child: Text('로그아웃')),
              ],
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: AppColors.primarySurface,
                    child: Text(
                      admin.name.isEmpty ? '?' : admin.name.characters.first,
                      style: AppTypography.bodyStrong.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(admin.name, style: AppTypography.bodyStrong),
                      Text(admin.role.label, style: AppTypography.caption),
                    ],
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  const Icon(
                    Icons.expand_more_rounded,
                    size: AppSizes.icon,
                    color: AppColors.ink500,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

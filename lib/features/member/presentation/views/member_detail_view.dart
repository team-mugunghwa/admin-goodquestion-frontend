import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/network/page_result.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formats.dart';
import '../../../../core/widgets/app_data_table.dart';
import '../../../../core/widgets/app_dialogs.dart';
import '../../../../core/widgets/app_page.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../../core/widgets/app_status_chip.dart';
import '../../domain/entities/member.dart';
import '../../domain/usecases/member_use_cases.dart';
import '../viewmodels/member_detail_view_model.dart';

class MemberDetailView extends StatelessWidget {
  const MemberDetailView({required this.parentId, super.key});

  final String parentId;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      key: ValueKey(parentId),
      create: (_) => MemberDetailViewModel(
        getMember: getIt<GetMemberUseCase>(),
        getStorySessions: getIt<GetStorySessionsUseCase>(),
        suspendMember: getIt<SuspendMemberUseCase>(),
        restoreMember: getIt<RestoreMemberUseCase>(),
        revokeLoginSessions: getIt<RevokeLoginSessionsUseCase>(),
        parentId: parentId,
      )..load(),
      child: const _MemberDetailBody(),
    );
  }
}

class _MemberDetailBody extends StatelessWidget {
  const _MemberDetailBody();

  Future<void> _suspend(BuildContext context) async {
    final reason = await showPromptDialog(
      context,
      title: '계정을 정지할까요?',
      message: '정지하면 로그인이 막히고, 지금 로그인돼 있는 기기도 끊깁니다.\n'
          '학습 기록과 리포트는 그대로 남습니다.',
      label: '정지 사유 (기록에 남습니다)',
      confirmLabel: '정지',
    );
    if (reason == null || !context.mounted) return;

    final vm = context.read<MemberDetailViewModel>();
    final ok = await vm.suspend(reason);
    if (!context.mounted) return;
    showResultSnackBar(
      context,
      success: ok,
      message: ok ? '계정을 정지했습니다.' : (vm.errorMessage ?? '처리하지 못했습니다.'),
    );
  }

  Future<void> _restore(BuildContext context) async {
    final vm = context.read<MemberDetailViewModel>();
    final ok = await vm.restore();
    if (!context.mounted) return;
    showResultSnackBar(
      context,
      success: ok,
      message: ok ? '정지를 해제했습니다.' : (vm.errorMessage ?? '처리하지 못했습니다.'),
    );
  }

  Future<void> _revokeSessions(BuildContext context) async {
    final confirmed = await showConfirmDialog(
      context,
      title: '로그인 세션을 모두 끊을까요?',
      message: '이 사용자의 모든 기기에서 로그아웃됩니다. 계정은 그대로라 다시 로그인할 수 있습니다.\n'
          '기기 분실이나 계정 공유 신고에 씁니다.',
      confirmLabel: '세션 종료',
      destructive: true,
    );
    if (!confirmed || !context.mounted) return;

    final vm = context.read<MemberDetailViewModel>();
    final ok = await vm.revokeLoginSessions();
    if (!context.mounted) return;
    showResultSnackBar(
      context,
      success: ok,
      message: ok ? '로그인 세션을 끊었습니다.' : (vm.errorMessage ?? '처리하지 못했습니다.'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<MemberDetailViewModel>();
    final member = vm.member;

    return AppPage(
      title: member?.name ?? '사용자 상세',
      backRoute: AppRoutes.members,
      actions: [
        if (member != null) ...[
          OutlinedButton(
            onPressed: vm.isBusy ? null : () => _revokeSessions(context),
            child: const Text('로그인 세션 종료'),
          ),
          if (member.status == MemberStatus.suspended)
            FilledButton(
              onPressed: vm.isBusy ? null : () => _restore(context),
              child: const Text('정지 해제'),
            )
          else
            FilledButton(
              onPressed: vm.isBusy ? null : () => _suspend(context),
              style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
              child: const Text('계정 정지'),
            ),
        ],
      ],
      child: AppStateView(
        state: vm.state,
        errorMessage: vm.errorMessage,
        onRetry: () => context.read<MemberDetailViewModel>().load(),
        builder: (context) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (member!.status == MemberStatus.suspended)
              _SuspendedBanner(member: member),
            _ProfileCard(member: member),
            const SizedBox(height: AppSpacing.lg),
            _ChildrenCard(children: member.children),
            const SizedBox(height: AppSpacing.lg),
            _LoginSessionsCard(sessions: member.loginSessions),
            const SizedBox(height: AppSpacing.lg),
            _StorySessionsCard(sessions: vm.sessions),
          ],
        ),
      ),
    );
  }
}

class _SuspendedBanner extends StatelessWidget {
  const _SuspendedBanner({required this.member});

  final MemberDetail member;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.dangerSurface,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '정지된 계정입니다',
            style: AppTypography.bodyStrong.copyWith(color: AppColors.danger),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${Formats.dateTime(member.suspendedAt)} / ${member.suspendedReason ?? "사유 없음"}',
            style: AppTypography.caption.copyWith(color: AppColors.danger),
          ),
        ],
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.member});

  final MemberDetail member;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      title: '계정 정보',
      child: Wrap(
        spacing: AppSpacing.xxl,
        runSpacing: AppSpacing.lg,
        children: [
          _Field(label: '이름', value: member.name),
          _Field(label: '이메일', value: member.email ?? '-'),
          _Field(
            label: '가입 경로',
            value: switch (member.provider) {
              'KAKAO' => '카카오',
              'GOOGLE' => '구글',
              _ => '이메일',
            },
          ),
          _Field(label: '가입일', value: Formats.date(member.createdAt)),
          _Field(label: '마지막 접속 IP', value: member.lastLoginIp ?? '-'),
          _Field(
            label: '로그인 잠금',
            value: member.locked
                ? '${Formats.dateTime(member.lockedUntil)} 까지'
                : '없음',
          ),
          _Field(label: '문의 수', value: '${member.inquiryCount}건'),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTypography.caption),
          const SizedBox(height: 2),
          Text(value, style: AppTypography.body),
        ],
      ),
    );
  }
}

class _ChildrenCard extends StatelessWidget {
  const _ChildrenCard({required this.children});

  final List<ChildProfile> children;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) {
      return AppCard(
        title: '아이 프로필',
        child: Text(
          '등록된 아이가 없습니다. 가입만 하고 아직 시작하지 않은 계정입니다.',
          style: AppTypography.caption,
        ),
      );
    }
    return AppCard(
      title: '아이 프로필',
      child: Wrap(
        spacing: AppSpacing.lg,
        runSpacing: AppSpacing.lg,
        children: [
          for (final child in children)
            Container(
              width: 200,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(child.name, style: AppTypography.bodyStrong),
                  const SizedBox(height: 2),
                  Text(
                    '${child.birthYear}년생 / 등록 ${Formats.date(child.createdAt)}',
                    style: AppTypography.caption,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _LoginSessionsCard extends StatelessWidget {
  const _LoginSessionsCard({required this.sessions});

  final List<LoginSession> sessions;

  @override
  Widget build(BuildContext context) {
    final active = sessions.where((session) => session.active).toList();
    return AppCard(
      title: '로그인 세션',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            active.isEmpty
                ? '살아 있는 세션이 없습니다.'
                : '${active.length}개 기기에서 로그인되어 있습니다.',
            style: AppTypography.body,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '세션을 끊어도 액세스 토큰이 만료될 때까지(최대 30분)는 기존 요청이 통과할 수 있습니다. '
            '즉시 차단이 필요하면 계정 정지를 함께 쓰세요.',
            style: AppTypography.caption,
          ),
          if (active.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            for (final session in active)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Row(
                  children: [
                    const AppStatusChip(label: '사용중', tone: StatusTone.positive),
                    const SizedBox(width: AppSpacing.md),
                    Text(
                      '로그인 ${Formats.dateTime(session.createdAt)} / '
                      '만료 ${Formats.dateTime(session.expiresAt)}',
                      style: AppTypography.caption,
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _StorySessionsCard extends StatelessWidget {
  const _StorySessionsCard({required this.sessions});

  final PageResult<StorySessionSummary> sessions;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      title: '학습 기록',
      padding: EdgeInsets.zero,
      child: sessions.isEmpty
          ? Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Text('아직 진행한 이야기가 없습니다.', style: AppTypography.caption),
            )
          : AppPagedTable<StorySessionSummary>(
              result: sessions,
              rowKey: (session) => session.id,
              onPageChanged: (nextPage) => context
                  .read<MemberDetailViewModel>()
                  .loadSessions(page: nextPage),
              columns: [
                AppColumn(
                  label: '아이',
                  width: 100,
                  cellBuilder: (context, session) => Text(session.childName),
                ),
                AppColumn(
                  label: '이야기',
                  flex: 3,
                  cellBuilder: (context, session) => Row(
                    children: [
                      Flexible(
                        child: Text(
                          session.storyTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // 위험 신호가 감지된 세션은 확인이 필요합니다.
                      if (session.safetyFlagged)
                        const Padding(
                          padding: EdgeInsets.only(left: AppSpacing.sm),
                          child: Tooltip(
                            message: '확인이 필요한 발화가 감지된 세션',
                            child: Icon(
                              Icons.flag_rounded,
                              size: 14,
                              color: AppColors.danger,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                AppColumn(
                  label: '상태',
                  width: 90,
                  cellBuilder: (context, session) => AppStatusChip(
                    label: session.statusLabel,
                    tone: session.statusTone,
                  ),
                ),
                AppColumn(
                  label: '마지막 활동',
                  width: 140,
                  cellBuilder: (context, session) => Text(
                    Formats.dateTime(session.lastActivityAt),
                    style: AppTypography.caption,
                  ),
                ),
              ],
            ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/di/injector.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formats.dart';
import '../../../../core/widgets/app_data_table.dart';
import '../../../../core/widgets/app_form.dart';
import '../../../../core/widgets/app_page.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../../core/widgets/app_status_chip.dart';
import '../../domain/entities/member.dart';
import '../../domain/usecases/member_use_cases.dart';
import '../viewmodels/member_list_view_model.dart';

class MemberListView extends StatelessWidget {
  const MemberListView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => MemberListViewModel(getIt<GetMembersUseCase>())..load(),
      child: const _MemberListBody(),
    );
  }
}

class _MemberListBody extends StatelessWidget {
  const _MemberListBody();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<MemberListViewModel>();

    return AppPage(
      title: '사용자 관리',
      description: '보호자 계정과 아이 프로필, 학습 기록을 확인합니다.',
      scrollable: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppFilterBar(
            children: [
              AppSearchField(
                hintText: '이름 또는 이메일로 검색',
                initialValue: vm.keyword,
                onSubmitted: (value) =>
                    context.read<MemberListViewModel>().search(value),
              ),
              AppFilterDropdown<MemberStatus>(
                value: vm.status,
                items: MemberStatus.labels,
                allLabel: '전체 상태',
                onChanged: (value) =>
                    context.read<MemberListViewModel>().changeStatus(value),
              ),
            ],
          ),
          Expanded(
            child: SingleChildScrollView(
              child: AppCard(
                padding: EdgeInsets.zero,
                child: AppStateView(
                  state: vm.state,
                  errorMessage: vm.errorMessage,
                  onRetry: () => context.read<MemberListViewModel>().load(),
                  isEmpty: vm.members.isEmpty,
                  emptyTitle: '사용자가 없습니다',
                  emptyDescription: '검색 조건을 바꿔 보세요.',
                  builder: (context) => AppPagedTable<MemberSummary>(
                    result: vm.members,
                    rowKey: (member) => member.id,
                    onRowTap: (member) =>
                        context.go(AppRoutes.memberDetailOf(member.id)),
                    onPageChanged: (page) =>
                        context.read<MemberListViewModel>().load(page: page),
                    columns: [
                      AppColumn(
                        label: '이름',
                        flex: 2,
                        cellBuilder: (context, member) => Text(
                          member.name,
                          style: AppTypography.bodyStrong,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      AppColumn(
                        label: '이메일',
                        flex: 3,
                        cellBuilder: (context, member) => Text(
                          // 소셜 가입은 이메일이 없을 수 있습니다.
                          member.email ?? '-',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      AppColumn(
                        label: '가입 경로',
                        width: 90,
                        cellBuilder: (context, member) => Text(
                          switch (member.provider) {
                            'KAKAO' => '카카오',
                            'GOOGLE' => '구글',
                            _ => '이메일',
                          },
                        ),
                      ),
                      AppColumn(
                        label: '아이',
                        width: 70,
                        alignment: Alignment.centerRight,
                        cellBuilder: (context, member) => Text(
                          '${member.childCount}명',
                          style: AppTypography.number,
                        ),
                      ),
                      AppColumn(
                        label: '상태',
                        width: 120,
                        cellBuilder: (context, member) => Row(
                          children: [
                            AppStatusChip(
                              label: member.status.label,
                              tone: member.status.tone,
                            ),
                            // 잠금은 정지와 사유가 달라 따로 보여줍니다.
                            // 정지는 관리자가 막은 것이고 잠금은 실패가 쌓인 것입니다.
                            if (member.locked)
                              const Padding(
                                padding: EdgeInsets.only(left: AppSpacing.xs),
                                child: Tooltip(
                                  message: '로그인 실패로 잠김',
                                  child: Icon(
                                    AppIcons.locked,
                                    size: 14,
                                    color: AppColors.warning,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      AppColumn(
                        label: '가입일',
                        width: 110,
                        cellBuilder: (context, member) => Text(
                          Formats.date(member.createdAt),
                          style: AppTypography.caption,
                        ),
                      ),
                      // 상대 시간이 아니라 절대 시각으로 적습니다. 목록에서 "3일 전"이
                      // 섞이면 위아래 줄의 선후를 눈으로 못 가립니다.
                      AppColumn(
                        label: '마지막 접속',
                        width: 150,
                        cellBuilder: (context, member) => Text(
                          Formats.dateTime(member.lastLoginAt),
                          style: AppTypography.caption,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}

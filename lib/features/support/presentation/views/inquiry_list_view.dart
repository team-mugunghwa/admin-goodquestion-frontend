import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

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
import '../../../auth/presentation/viewmodels/admin_session.dart';
import '../../domain/entities/inquiry.dart';
import '../../domain/usecases/support_use_cases.dart';
import '../viewmodels/inquiry_list_view_model.dart';

class InquiryListView extends StatelessWidget {
  const InquiryListView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => InquiryListViewModel(getIt<GetInquiriesUseCase>())..load(),
      child: const _InquiryListBody(),
    );
  }
}

class _InquiryListBody extends StatelessWidget {
  const _InquiryListBody();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<InquiryListViewModel>();

    return AppPage(
      title: '고객센터',
      description: '답변을 등록하면 사용자에게 알림이 가고 앱에서 바로 확인할 수 있습니다.',
      scrollable: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppFilterBar(
            children: [
              AppSearchField(
                hintText: '제목으로 검색',
                initialValue: vm.keyword,
                onSubmitted: (value) =>
                    context.read<InquiryListViewModel>().search(value),
              ),
              AppFilterDropdown<InquiryStatus>(
                value: vm.status,
                items: InquiryStatus.labels,
                allLabel: '전체 상태',
                onChanged: (value) =>
                    context.read<InquiryListViewModel>().changeStatus(value),
              ),
              AppFilterDropdown<InquiryCategory>(
                value: vm.category,
                items: InquiryCategory.labels,
                allLabel: '전체 분류',
                onChanged: (value) =>
                    context.read<InquiryListViewModel>().changeCategory(value),
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
                  onRetry: () => context.read<InquiryListViewModel>().load(),
                  isEmpty: vm.inquiries.isEmpty,
                  emptyTitle: vm.status == InquiryStatus.pending
                      ? '답변할 문의가 없습니다'
                      : '문의가 없습니다',
                  emptyDescription: vm.status == InquiryStatus.pending
                      ? '모든 문의에 답변했습니다.'
                      : null,
                  builder: (context) => AppPagedTable<InquirySummary>(
                    result: vm.inquiries,
                    rowKey: (inquiry) => inquiry.id,
                    onRowTap: (inquiry) =>
                        context.go(AppRoutes.inquiryDetailOf(inquiry.id)),
                    onPageChanged: (page) =>
                        context.read<InquiryListViewModel>().load(page: page),
                    columns: [
                      AppColumn(
                        label: '상태',
                        width: 90,
                        cellBuilder: (context, inquiry) => AppStatusChip(
                          label: inquiry.status.label,
                          tone: inquiry.status.tone,
                        ),
                      ),
                      AppColumn(
                        label: '제목',
                        flex: 4,
                        cellBuilder: (context, inquiry) => Text(
                          inquiry.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.bodyStrong,
                        ),
                      ),
                      AppColumn(
                        label: '분류',
                        width: 100,
                        cellBuilder: (context, inquiry) =>
                            Text(inquiry.category.label),
                      ),
                      AppColumn(
                        label: '작성자',
                        flex: 2,
                        cellBuilder: (context, inquiry) => Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              inquiry.parentName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (inquiry.parentEmail != null)
                              Text(
                                inquiry.parentEmail!,
                                style: AppTypography.caption,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                      AppColumn(
                        label: '담당자',
                        flex: 2,
                        cellBuilder: (context, inquiry) =>
                            _AssigneeCell(inquiry: inquiry),
                      ),
                      AppColumn(
                        label: '접수일',
                        width: 130,
                        cellBuilder: (context, inquiry) =>
                            _WaitingCell(inquiry: inquiry),
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

/// 담당자 칸. 내 담당이면 색으로 띄웁니다.
class _AssigneeCell extends StatelessWidget {
  const _AssigneeCell({required this.inquiry});

  final InquirySummary inquiry;

  @override
  Widget build(BuildContext context) {
    final assignee = inquiry.assigneeEmail;
    if (assignee == null) {
      return Text('-', style: AppTypography.caption);
    }
    final mine = assignee == context.watch<AdminSession>().admin?.email;
    return Text(
      mine ? '나' : assignee,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: mine
          ? AppTypography.bodyStrong.copyWith(color: AppColors.primary)
          : AppTypography.caption,
    );
  }
}

/// 접수일과 기다린 시간.
///
/// 답변 대기 중이면 경과를 색으로 띄웁니다. 하루까지는 보통, 사흘까지는 주황,
/// 그 뒤로는 빨강입니다. 목록을 열자마자 "무엇부터 답해야 하는가"가 보여야 합니다.
class _WaitingCell extends StatelessWidget {
  const _WaitingCell({required this.inquiry});

  final InquirySummary inquiry;

  @override
  Widget build(BuildContext context) {
    final waiting = inquiry.waitingSince(DateTime.now());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(Formats.date(inquiry.createdAt), style: AppTypography.caption),
        if (waiting != null)
          Text(
            '${_label(waiting)} 대기',
            style: AppTypography.caption.copyWith(
              color: _color(waiting),
              fontWeight:
                  waiting.inHours >= 24 ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
      ],
    );
  }

  static String _label(Duration waiting) {
    if (waiting.inDays >= 1) return '${waiting.inDays}일';
    if (waiting.inHours >= 1) return '${waiting.inHours}시간';
    return '${waiting.inMinutes}분';
  }

  static Color _color(Duration waiting) {
    if (waiting.inHours >= 72) return AppColors.danger;
    if (waiting.inHours >= 24) return AppColors.warning;
    return AppColors.ink500;
  }
}

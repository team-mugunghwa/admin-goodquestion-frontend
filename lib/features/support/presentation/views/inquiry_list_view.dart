import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formats.dart';
import '../../../../core/widgets/app_data_table.dart';
import '../../../../core/widgets/app_form.dart';
import '../../../../core/widgets/app_page.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../../core/widgets/app_status_chip.dart';
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
                        label: '접수일',
                        width: 130,
                        cellBuilder: (context, inquiry) => Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              Formats.date(inquiry.createdAt),
                              style: AppTypography.caption,
                            ),
                            // 대기 중인 문의는 "얼마나 기다렸는가"가 중요합니다.
                            if (inquiry.status == InquiryStatus.pending)
                              Text(
                                Formats.relative(inquiry.createdAt),
                                style: AppTypography.caption,
                              ),
                          ],
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

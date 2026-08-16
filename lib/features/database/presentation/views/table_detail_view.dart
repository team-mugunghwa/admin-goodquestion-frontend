import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formats.dart';
import '../../../../core/widgets/app_page.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../domain/usecases/database_use_cases.dart';
import '../viewmodels/table_detail_view_model.dart';
import '../widgets/column_list.dart';
import '../widgets/row_grid.dart';

/// 테이블 하나. 구조 탭과 데이터 탭으로 나눕니다.
///
/// 구조를 먼저 보여주는 이유: 값만 보면 컬럼 이름이 무슨 뜻인지 알 수 없습니다.
/// 이 화면을 여는 사람은 대부분 "이게 무슨 값이지"에서 출발합니다.
class TableDetailView extends StatelessWidget {
  const TableDetailView({required this.tableName, super.key});

  final String tableName;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      key: ValueKey(tableName),
      create: (_) => TableDetailViewModel(
        getTable: getIt<GetTableUseCase>(),
        getRows: getIt<GetTableRowsUseCase>(),
        tableName: tableName,
      )..load(),
      child: const _TableDetailBody(),
    );
  }
}

class _TableDetailBody extends StatefulWidget {
  const _TableDetailBody();

  @override
  State<_TableDetailBody> createState() => _TableDetailBodyState();
}

class _TableDetailBodyState extends State<_TableDetailBody>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController = TabController(length: 2, vsync: this);

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<TableDetailViewModel>();
    final detail = vm.detail;

    return AppPage(
      title: detail?.comment?.split('.').first ?? vm.tableName,
      backRoute: AppRoutes.database,
      description: detail == null
          ? vm.tableName
          : '${detail.name} / ${detail.group} / 컬럼 ${detail.columns.length}개 / '
                '${Formats.count(detail.rowCount)}행',
      scrollable: false,
      child: AppStateView(
        state: vm.state,
        errorMessage: vm.errorMessage,
        onRetry: () => context.read<TableDetailViewModel>().load(),
        builder: (context) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (detail!.containsPersonalData) const _PersonalDataBanner(),
            if (detail.comment != null) ...[
              Text(detail.comment!, style: AppTypography.body),
              const SizedBox(height: AppSpacing.lg),
            ],
            TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelStyle: AppTypography.bodyStrong,
              tabs: [
                Tab(text: '구조 (${detail.columns.length})'),
                Tab(text: '데이터 (${Formats.count(detail.rowCount)})'),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  SingleChildScrollView(child: ColumnList(detail: detail)),
                  const RowGrid(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 개인정보가 든 테이블임을 열기 전에 알립니다.
///
/// 막지는 않습니다. 관리자는 사용자 관리 화면에서 이미 이름과 이메일을 봅니다.
/// 다만 여기서는 아이 발화 원문처럼 무게가 다른 값도 함께 보이므로, 무엇을 보고
/// 있는지 알고 보는 것과 모르고 보는 것을 구분하려는 것입니다.
class _PersonalDataBanner extends StatelessWidget {
  const _PersonalDataBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.warningSurface,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.privacy_tip_rounded,
            size: AppSizes.icon,
            color: AppColors.warning,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              '개인정보가 들어 있는 테이블입니다. 데이터 탭을 열면 누가 언제 봤는지 감사 로그에 남습니다. '
              '필요한 것만 확인하고 화면을 캡처하거나 밖으로 옮기지 마세요.',
              style: AppTypography.caption.copyWith(color: AppColors.warning),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/di/injector.dart';
import '../../../../core/network/page_result.dart';
import '../../../../core/presentation/base_view_model.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formats.dart';
import '../../../../core/widgets/app_data_table.dart';
import '../../../../core/widgets/app_form.dart';
import '../../../../core/widgets/app_page.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../domain/audit_log.dart';

/// 감사 로그. 조회만 있어 ViewModel 을 이 파일에 함께 둡니다.
class AuditLogViewModel extends BaseViewModel {
  AuditLogViewModel(this._repository);

  final AuditLogRepository _repository;

  PageResult<AuditLog> _logs = const PageResult.empty();
  String? _targetType;

  PageResult<AuditLog> get logs => _logs;
  String? get targetType => _targetType;

  Future<void> load({int page = 0}) => guard(() async {
    _logs = await _repository.getLogs(
      targetType: _targetType,
      page: page,
      size: AppConfig.defaultPageSize,
    );
  });

  Future<void> changeTargetType(String? targetType) {
    _targetType = targetType;
    return load();
  }
}

class AuditLogView extends StatelessWidget {
  const AuditLogView({super.key});

  /// 필터 목록. 서버가 주는 targetType 문자열을 그대로 씁니다.
  static const Map<String, String> _targetTypes = {
    'NOTICE': '공지',
    'GUIDE': '이용안내',
    'STORY': '이야기',
    'SCENE': '장면',
    'CHARACTER': '캐릭터',
    'INQUIRY': '문의',
    'PARENT': '사용자',
    'ADMIN_ACCOUNT': '관리자 계정',
  };

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuditLogViewModel(getIt<AuditLogRepository>())..load(),
      child: Builder(
        builder: (context) {
          final vm = context.watch<AuditLogViewModel>();
          return AppPage(
            title: '감사 로그',
            description: '관리자가 상태를 바꾼 조작만 남깁니다. 조회는 남기지 않습니다.',
            scrollable: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppFilterBar(
                  children: [
                    AppFilterDropdown<String>(
                      value: vm.targetType,
                      items: _targetTypes,
                      allLabel: '전체 대상',
                      width: 180,
                      onChanged: (value) => context
                          .read<AuditLogViewModel>()
                          .changeTargetType(value),
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
                        onRetry: () => context.read<AuditLogViewModel>().load(),
                        isEmpty: vm.logs.isEmpty,
                        emptyTitle: '기록이 없습니다',
                        builder: (context) => AppPagedTable<AuditLog>(
                          result: vm.logs,
                          rowKey: (log) => log.id,
                          onPageChanged: (page) => context
                              .read<AuditLogViewModel>()
                              .load(page: page),
                          columns: [
                            AppColumn(
                              label: '시각',
                              width: 150,
                              cellBuilder: (context, log) => Text(
                                Formats.dateTime(log.createdAt),
                                style: AppTypography.caption,
                              ),
                            ),
                            AppColumn(
                              label: '관리자',
                              flex: 2,
                              cellBuilder: (context, log) => Text(
                                log.adminEmail,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            AppColumn(
                              label: '대상',
                              width: 100,
                              cellBuilder: (context, log) =>
                                  Text(log.targetLabel),
                            ),
                            AppColumn(
                              label: '조작',
                              width: 90,
                              cellBuilder: (context, log) =>
                                  Text(log.actionLabel),
                            ),
                            AppColumn(
                              label: '내용',
                              flex: 4,
                              cellBuilder: (context, log) => Text(
                                log.summary ?? '-',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            AppColumn(
                              label: 'IP',
                              width: 120,
                              cellBuilder: (context, log) => Text(
                                log.ip ?? '-',
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
        },
      ),
    );
  }
}

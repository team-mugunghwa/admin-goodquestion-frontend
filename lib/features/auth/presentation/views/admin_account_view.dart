import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/di/injector.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formats.dart';
import '../../../../core/widgets/app_data_table.dart';
import '../../../../core/widgets/app_dialogs.dart';
import '../../../../core/widgets/app_form.dart';
import '../../../../core/widgets/app_page.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../../core/widgets/app_status_chip.dart';
import '../../domain/entities/admin_account.dart';
import '../../domain/usecases/auth_use_cases.dart';
import '../viewmodels/admin_account_view_model.dart';
import '../viewmodels/admin_session.dart';

/// 관리자 계정 관리. 최고관리자에게만 메뉴가 보입니다.
class AdminAccountView extends StatelessWidget {
  const AdminAccountView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AdminAccountViewModel(
        getAdmins: getIt<GetAdminsUseCase>(),
        createAdmin: getIt<CreateAdminUseCase>(),
        updateAdmin: getIt<UpdateAdminUseCase>(),
        deleteAdmin: getIt<DeleteAdminUseCase>(),
      )..load(),
      child: const _AdminAccountBody(),
    );
  }
}

class _AdminAccountBody extends StatelessWidget {
  const _AdminAccountBody();

  Future<void> _create(BuildContext context) async {
    final draft = await _showCreateDialog(context);
    if (draft == null || !context.mounted) return;

    final vm = context.read<AdminAccountViewModel>();
    final ok = await vm.create(
      email: draft.email,
      password: draft.password,
      name: draft.name,
      role: draft.role,
    );
    if (!context.mounted) return;
    showResultSnackBar(
      context,
      success: ok,
      message: ok ? '관리자 계정을 만들었습니다.' : (vm.errorMessage ?? '만들지 못했습니다.'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AdminAccountViewModel>();
    final me = context.watch<AdminSession>().admin;

    return AppPage(
      title: '관리자 계정',
      description: '최고관리자만 계정을 만들고 지울 수 있습니다.',
      scrollable: false,
      actions: [
        FilledButton.icon(
          onPressed: () => _create(context),
          icon: const Icon(AppIcons.add, size: AppSizes.icon),
          label: const Text('계정 추가'),
        ),
      ],
      child: SingleChildScrollView(
        child: AppCard(
          padding: EdgeInsets.zero,
          child: AppStateView(
            state: vm.state,
            errorMessage: vm.errorMessage,
            onRetry: () => context.read<AdminAccountViewModel>().load(),
            isEmpty: vm.admins.isEmpty,
            emptyTitle: '관리자 계정이 없습니다',
            builder: (context) => AppPagedTable<AdminAccount>(
              result: vm.admins,
              rowKey: (admin) => admin.id,
              onPageChanged: (page) =>
                  context.read<AdminAccountViewModel>().load(page: page),
              columns: [
                AppColumn(
                  label: '이름',
                  flex: 2,
                  cellBuilder: (context, admin) => Row(
                    children: [
                      Flexible(
                        child: Text(
                          admin.name,
                          style: AppTypography.bodyStrong,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // 자기 계정은 정지/삭제가 막혀 있습니다. 그 이유를 표에서도 보이게 합니다.
                      if (admin.id == me?.id)
                        const Padding(
                          padding: EdgeInsets.only(left: AppSpacing.sm),
                          child: AppStatusChip(
                            label: '나',
                            tone: StatusTone.info,
                          ),
                        ),
                    ],
                  ),
                ),
                AppColumn(
                  label: '이메일',
                  flex: 3,
                  cellBuilder: (context, admin) => Text(
                    admin.email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                AppColumn(
                  label: '권한',
                  width: 110,
                  cellBuilder: (context, admin) => Text(admin.role.label),
                ),
                AppColumn(
                  label: '상태',
                  width: 90,
                  cellBuilder: (context, admin) => AppStatusChip(
                    label: admin.status.label,
                    tone: admin.status == AdminStatus.active
                        ? StatusTone.positive
                        : StatusTone.negative,
                  ),
                ),
                AppColumn(
                  label: '마지막 로그인',
                  width: 150,
                  cellBuilder: (context, admin) => Text(
                    Formats.dateTime(admin.lastLoginAt),
                    style: AppTypography.caption,
                  ),
                ),
                AppColumn(
                  label: '',
                  width: 100,
                  cellBuilder: (context, admin) => _RowActions(
                    admin: admin,
                    isSelf: admin.id == me?.id,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RowActions extends StatelessWidget {
  const _RowActions({required this.admin, required this.isSelf});

  final AdminAccount admin;
  final bool isSelf;

  @override
  Widget build(BuildContext context) {
    // 자기 계정에는 아무 조작도 두지 않습니다. 스스로를 정지시키거나 지우면
    // 마지막 최고관리자가 사라져 DB 를 직접 고치는 것 말고는 되돌릴 방법이 없습니다.
    if (isSelf) {
      return Text('-', style: AppTypography.caption);
    }

    final vm = context.read<AdminAccountViewModel>();
    return PopupMenuButton<String>(
      tooltip: '관리',
      icon: const Icon(AppIcons.more, size: AppSizes.icon, color: AppColors.ink500),
      onSelected: (value) async {
        var ok = false;
        var message = '';
        switch (value) {
          case 'suspend':
            ok = await vm.changeStatus(admin, AdminStatus.suspended);
            message = ok ? '계정을 정지했습니다.' : (vm.errorMessage ?? '처리하지 못했습니다.');
          case 'activate':
            ok = await vm.changeStatus(admin, AdminStatus.active);
            message = ok ? '정지를 해제했습니다.' : (vm.errorMessage ?? '처리하지 못했습니다.');
          case 'promote':
            ok = await vm.changeRole(admin, AdminRole.superAdmin);
            message = ok ? '최고관리자로 바꿨습니다.' : (vm.errorMessage ?? '처리하지 못했습니다.');
          case 'demote':
            ok = await vm.changeRole(admin, AdminRole.admin);
            message = ok ? '관리자로 바꿨습니다.' : (vm.errorMessage ?? '처리하지 못했습니다.');
          case 'delete':
            if (!context.mounted) return;
            final confirmed = await showConfirmDialog(
              context,
              title: '계정을 삭제할까요?',
              message: '${admin.email}\n\n삭제해도 이 계정이 남긴 감사 로그는 그대로 남습니다.',
              confirmLabel: '삭제',
              destructive: true,
            );
            if (!confirmed) return;
            ok = await vm.delete(admin.id);
            message = ok ? '계정을 삭제했습니다.' : (vm.errorMessage ?? '삭제하지 못했습니다.');
        }
        if (!context.mounted) return;
        showResultSnackBar(context, success: ok, message: message);
      },
      itemBuilder: (context) => [
        if (admin.status == AdminStatus.active)
          const PopupMenuItem(value: 'suspend', child: Text('정지'))
        else
          const PopupMenuItem(value: 'activate', child: Text('정지 해제')),
        if (admin.role == AdminRole.admin)
          const PopupMenuItem(value: 'promote', child: Text('최고관리자로'))
        else
          const PopupMenuItem(value: 'demote', child: Text('관리자로')),
        const PopupMenuItem(value: 'delete', child: Text('삭제')),
      ],
    );
  }
}

class _AdminDraft {
  const _AdminDraft({
    required this.email,
    required this.password,
    required this.name,
    required this.role,
  });

  final String email;
  final String password;
  final String name;
  final AdminRole role;
}

Future<_AdminDraft?> _showCreateDialog(BuildContext context) {
  final formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final nameController = TextEditingController();
  var role = AdminRole.admin;

  return showDialog<_AdminDraft>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Text('관리자 계정 추가'),
        content: SizedBox(
          width: 440,
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppField(
                  label: '이메일',
                  required: true,
                  child: TextFormField(
                    controller: emailController,
                    autofocus: true,
                    validator: (value) => (value == null || !value.contains('@'))
                        ? '올바른 이메일을 입력해 주세요.'
                        : null,
                  ),
                ),
                AppField(
                  label: '이름',
                  required: true,
                  child: TextFormField(
                    controller: nameController,
                    validator: (value) => (value == null || value.trim().isEmpty)
                        ? '이름을 입력해 주세요.'
                        : null,
                  ),
                ),
                AppField(
                  label: '초기 비밀번호',
                  required: true,
                  hint: '10자 이상. 전달 후 본인이 바꾸게 하세요.',
                  child: TextFormField(
                    controller: passwordController,
                    validator: (value) => (value == null || value.length < 10)
                        ? '10자 이상 입력해 주세요.'
                        : null,
                  ),
                ),
                AppField(
                  label: '권한',
                  hint: '최고관리자만 계정을 만들고 지울 수 있습니다.',
                  child: DropdownButtonFormField<AdminRole>(
                    initialValue: role,
                    items: [
                      for (final value in AdminRole.values)
                        DropdownMenuItem(
                          value: value,
                          child: Text(value.label),
                        ),
                    ],
                    onChanged: (value) => setState(() => role = value ?? role),
                  ),
                ),
              ],
            ),
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () {
              if (!(formKey.currentState?.validate() ?? false)) return;
              Navigator.of(context).pop(
                _AdminDraft(
                  email: emailController.text.trim(),
                  password: passwordController.text,
                  name: nameController.text.trim(),
                  role: role,
                ),
              );
            },
            child: const Text('만들기'),
          ),
        ],
      ),
    ),
  );
}

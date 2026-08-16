import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_dialogs.dart';
import '../../../../core/widgets/app_form.dart';
import '../../../../core/widgets/app_page.dart';
import '../../domain/usecases/auth_use_cases.dart';
import '../viewmodels/admin_session.dart';

/// 내 계정 - 비밀번호 변경.
///
/// 비밀번호를 바꾸면 서버가 이 계정의 리프레시 토큰을 전부 끊습니다. 그래서 저장
/// 직후 로그아웃되어 로그인 화면으로 돌아갑니다 - 바꾼 이유가 유출 의심일 수 있어
/// 다른 기기의 세션을 남겨 두면 바꾼 의미가 없습니다.
class MyAccountView extends StatefulWidget {
  const MyAccountView({super.key});

  @override
  State<MyAccountView> createState() => _MyAccountViewState();
}

class _MyAccountViewState extends State<MyAccountView> {
  final _formKey = GlobalKey<FormState>();
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _saving = true);
    try {
      await getIt<ChangePasswordUseCase>()(
        currentPassword: _currentController.text,
        newPassword: _newController.text,
      );
      if (!mounted) return;
      showResultSnackBar(
        context,
        success: true,
        message: '비밀번호를 바꿨습니다. 다시 로그인해 주세요.',
      );
      // 서버가 토큰을 끊었으므로 세션도 비웁니다. 라우터가 로그인 화면으로 보냅니다.
      await context.read<AdminSession>().signOut();
    } catch (e) {
      if (!mounted) return;
      showResultSnackBar(
        context,
        success: false,
        message: e is Failure ? e.message : '비밀번호를 바꾸지 못했습니다.',
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminSession>().admin;

    return AppPage(
      title: '내 계정',
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (admin != null)
                AppCard(
                  title: '계정 정보',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(admin.name, style: AppTypography.bodyStrong),
                      Text(admin.email, style: AppTypography.caption),
                      const SizedBox(height: AppSpacing.sm),
                      Text('권한: ${admin.role.label}', style: AppTypography.caption),
                    ],
                  ),
                ),
              const SizedBox(height: AppSpacing.lg),
              AppCard(
                title: '비밀번호 변경',
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AppField(
                        label: '현재 비밀번호',
                        required: true,
                        child: TextFormField(
                          controller: _currentController,
                          obscureText: true,
                          validator: (value) =>
                              (value == null || value.isEmpty)
                              ? '현재 비밀번호를 입력해 주세요.'
                              : null,
                        ),
                      ),
                      AppField(
                        label: '새 비밀번호',
                        required: true,
                        hint: '10자 이상으로 정해 주세요.',
                        child: TextFormField(
                          controller: _newController,
                          obscureText: true,
                          validator: (value) => (value == null || value.length < 10)
                              ? '10자 이상 입력해 주세요.'
                              : null,
                        ),
                      ),
                      AppField(
                        label: '새 비밀번호 확인',
                        required: true,
                        child: TextFormField(
                          controller: _confirmController,
                          obscureText: true,
                          onFieldSubmitted: (_) => _submit(),
                          validator: (value) => value != _newController.text
                              ? '새 비밀번호와 다릅니다.'
                              : null,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.warningSurface,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        child: Text(
                          '바꾸면 모든 기기에서 로그아웃되고 다시 로그인해야 합니다.',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.warning,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      FilledButton(
                        onPressed: _saving ? null : _submit,
                        child: Text(_saving ? '변경 중...' : '비밀번호 변경'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

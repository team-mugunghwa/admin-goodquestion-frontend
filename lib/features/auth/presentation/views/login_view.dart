import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_form.dart';
import '../viewmodels/admin_session.dart';

/// 로그인. 셸 바깥에 있는 유일한 화면입니다.
///
/// 로그인 성공 후의 이동은 여기서 하지 않습니다. 세션이 바뀌면 라우터의 redirect 가
/// 알아서 보냅니다 — 화면이 직접 `context.go` 를 부르면 그 판단이 두 군데로 갈립니다.
class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    await context.read<AdminSession>().signIn(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<AdminSession>();

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.xxl),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: AppColors.ink100),
                boxShadow: AppColors.cardShadow,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Q',
                            style: AppTypography.bodyStrong.copyWith(
                              color: AppColors.surface,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Text('굿퀘스천 관리자', style: AppTypography.pageTitle),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      '운영자 계정으로 로그인하세요.',
                      style: AppTypography.caption,
                    ),
                    const SizedBox(height: AppSpacing.xxl),

                    AppField(
                      label: '이메일',
                      child: TextFormField(
                        controller: _emailController,
                        autofocus: true,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          hintText: 'admin@goodquestion.kr',
                        ),
                        validator: (value) =>
                            (value == null || value.trim().isEmpty)
                            ? '이메일을 입력해 주세요.'
                            : null,
                      ),
                    ),
                    AppField(
                      label: '비밀번호',
                      child: TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        // 비밀번호 칸에서 엔터로 바로 로그인되게 합니다.
                        onFieldSubmitted: (_) => _submit(),
                        validator: (value) => (value == null || value.isEmpty)
                            ? '비밀번호를 입력해 주세요.'
                            : null,
                      ),
                    ),

                    if (session.errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.dangerSurface,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        child: Text(
                          session.errorMessage!,
                          style: AppTypography.body.copyWith(
                            color: AppColors.danger,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                    ],

                    FilledButton(
                      onPressed: session.isSigningIn ? null : _submit,
                      child: session.isSigningIn
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.surface,
                              ),
                            )
                          : const Text('로그인'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

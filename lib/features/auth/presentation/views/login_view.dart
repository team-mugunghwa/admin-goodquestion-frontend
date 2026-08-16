import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_form.dart';
import '../viewmodels/admin_session.dart';
import '../widgets/hangul_composition.dart';

/// 로그인. 셸 바깥에 있는 유일한 화면입니다.
///
/// 로그인 성공 후의 이동은 여기서 하지 않습니다. 세션이 바뀌면 라우터의 redirect 가
/// 알아서 보냅니다 - 화면이 직접 `context.go` 를 부르면 그 판단이 두 군데로 갈립니다.
///
/// ## 화면을 둘로 나눈 이유
///
/// 왼쪽은 할 일(로그인), 오른쪽은 이 서비스가 무엇인지입니다. 관리자 콘솔은 팀
/// 바깥 사람도 보게 되는 화면이라, 로그인 칸만 덩그러니 있는 것보다 무엇을 하는
/// 곳인지 한 문장으로 알려 주는 편이 낫습니다.
///
/// 오른쪽에는 **문장 하나만** 둡니다. 그림을 여럿 늘어놓으면 정작 로그인 칸에서
/// 시선이 흩어집니다. 좁은 화면에서는 오른쪽을 통째로 접습니다.
class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  /// 이 폭보다 좁으면 소개 영역을 접고 로그인만 보여 줍니다.
  static const double _splitBreakpoint = 900;

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
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final form = _LoginForm(
            formKey: _formKey,
            emailController: _emailController,
            passwordController: _passwordController,
            onSubmit: _submit,
          );

          if (constraints.maxWidth < _splitBreakpoint) {
            return form;
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(flex: 5, child: form),
              const Expanded(flex: 6, child: _BrandPanel()),
            ],
          );
        },
      ),
    );
  }
}

class _LoginForm extends StatelessWidget {
  const _LoginForm({
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final Future<void> Function() onSubmit;

  @override
  Widget build(BuildContext context) {
    final session = context.watch<AdminSession>();

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                const HangulComposition(),
                const SizedBox(height: AppSpacing.xl),

                Text('관리자 로그인', style: AppTypography.pageTitle),
                const SizedBox(height: AppSpacing.xs),
                Text('운영자 계정으로 로그인해 주세요.', style: AppTypography.caption),
                const SizedBox(height: AppSpacing.xl),

                AppField(
                  label: '이메일',
                  child: TextFormField(
                    controller: emailController,
                    autofocus: true,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      hintText: 'admin@goodquestion.kr',
                    ),
                    validator: (value) => (value == null || value.trim().isEmpty)
                        ? '이메일을 입력해 주세요.'
                        : null,
                  ),
                ),
                AppField(
                  label: '비밀번호',
                  child: TextFormField(
                    controller: passwordController,
                    obscureText: true,
                    // 비밀번호 칸에서 엔터로 바로 로그인되게 합니다.
                    onFieldSubmitted: (_) => onSubmit(),
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
                      style: AppTypography.body.copyWith(color: AppColors.danger),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],

                SizedBox(
                  height: 48,
                  child: FilledButton(
                    onPressed: session.isSigningIn ? null : onSubmit,
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
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 오른쪽 소개 영역.
///
/// 좌측 메뉴와 같은 남색을 씁니다. 이 콘솔에서 어두운 면은 이 한 가지뿐이라,
/// 로그인 화면에서도 같은 면을 쓰면 들어간 뒤와 이어져 보입니다.
class _BrandPanel extends StatelessWidget {
  const _BrandPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      // clipBehavior 를 주려면 color 가 아니라 decoration 이어야 합니다.
      decoration: const BoxDecoration(color: AppColors.navSurface),
      child: const Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.xxxl,
          vertical: AppSpacing.xxl,
        ),
        child: Align(alignment: Alignment.centerLeft, child: _Statement()),
      ),
    );
  }
}

/// 꼭 보여 줄 한 문장.
///
/// 핵심 두 마디만 흰색으로 올려 문장 안에서 눈이 먼저 닿게 합니다. 색을 새로
/// 만들지 않고 밝기 차이만 씁니다.
class _Statement extends StatelessWidget {
  const _Statement();

  @override
  Widget build(BuildContext context) {
    final base = AppTypography.pageTitle.copyWith(
      fontSize: 38,
      height: 1.5,
      fontWeight: FontWeight.w500,
      color: AppColors.navLabel,
    );
    final strong = base.copyWith(
      color: AppColors.surface,
      fontWeight: FontWeight.w700,
    );

    // 줄을 직접 나누고, 폭이 모자라면 글자 크기를 줄여 통째로 맞춥니다.
    //
    // 접히도록 두면 한국어가 단어 한가운데에서 끊깁니다("말하 / 기 자신감").
    // 줄바꿈만 고정하면 글꼴이나 창 폭이 조금 달라졌을 때 넘쳐서 잘립니다.
    // 둘을 같이 써야 어느 화면에서도 세 줄 구성이 그대로 유지됩니다.
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Text.rich(
        TextSpan(
          style: base,
          children: [
            const TextSpan(text: '굿퀘스천은 아이들의\n'),
            TextSpan(text: '말하기 자신감', style: strong),
            const TextSpan(text: '과\n'),
            TextSpan(text: '생각의 힘', style: strong),
            const TextSpan(text: '을 키워갑니다.'),
          ],
        ),
      ),
    );
  }
}


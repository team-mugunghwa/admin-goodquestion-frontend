import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/di/injector.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formats.dart';
import '../../../../core/widgets/app_dialogs.dart';
import '../../../../core/widgets/app_form.dart';
import '../../../../core/widgets/app_page.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../domain/entities/tts_vendor.dart';
import '../../domain/usecases/tts_vendor_use_cases.dart';
import '../viewmodels/tts_vendor_view_model.dart';

/// 설정 화면의 "음성 합성" 섹션.
///
/// 자기 ViewModel 을 자기가 만들고 자기가 불러옵니다. 설정 화면이 값을 모아
/// 들고 있으면 항목을 하나 더할 때마다 화면을 고쳐야 하고, 한 항목의 조회가
/// 실패하면 나머지까지 못 보게 됩니다.
class TtsVendorSection extends StatelessWidget {
  const TtsVendorSection({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => TtsVendorViewModel(
        getTtsVendor: getIt<GetTtsVendorUseCase>(),
        updateTtsVendor: getIt<UpdateTtsVendorUseCase>(),
      )..load(),
      child: Builder(
        builder: (context) {
          final vm = context.watch<TtsVendorViewModel>();
          return AppCard(
            title: '음성 합성',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 경고와 설명은 **상태 뷰 밖**에 둡니다. 조회가 실패했을 때
                // 이것들까지 같이 사라지면, 화면이 가장 위험한 순간에
                // 가장 적게 말하게 됩니다.
                const _KeyWarning(),
                const SizedBox(height: AppSpacing.xl),
                // 고를 것을 설명하는 글이 고르는 컨트롤보다 **위**에 옵니다.
                // 아래에 두었더니 1100x700 에서 접힌 자리 밖으로 밀려,
                // 무엇을 고르는지 모르는 채로 누르게 됩니다.
                const _VendorGuide(),
                const SizedBox(height: AppSpacing.xl),
                AppStateView(
                  state: vm.state,
                  errorMessage: vm.errorMessage,
                  onRetry: () => context.read<TtsVendorViewModel>().load(),
                  // 조회에 성공했으면 값이 반드시 들어 있습니다. AppStateView 는
                  // 성공 상태에서만 이 빌더를 부릅니다.
                  builder: (context) =>
                      _VendorPicker(setting: vm.setting!, busy: vm.isBusy),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _VendorPicker extends StatelessWidget {
  const _VendorPicker({required this.setting, required this.busy});

  final TtsVendorSetting setting;

  /// 저장이 도는 중. 컨트롤을 잠가 두 번 눌리는 것을 막습니다.
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppField(
          label: '합성 엔진',
          hint: '고르면 바로 저장됩니다. 저장 버튼은 따로 없습니다.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SegmentedButton<TtsVendor>(
                // 테마에 segmentedButtonTheme 이 없어서 그냥 두면 M3 가 만들어 낸
                // 색과 알약 모양이 나옵니다. AppColors 에 없는 색을 화면에
                // 내보내지 않도록 여기서 토큰으로 못박습니다.
                style: SegmentedButton.styleFrom(
                  foregroundColor: AppColors.ink700,
                  selectedForegroundColor: AppColors.primary,
                  selectedBackgroundColor: AppColors.primarySurface,
                  side: const BorderSide(color: AppColors.ink300),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  textStyle: AppTypography.bodyStrong,
                ),
                // 기본값은 내용만큼만 넓어져 폼 폭(670)에 한참 못 미칩니다.
                // 셋을 고르는 컨트롤이 왼쪽에 몰려 있으면 나머지 여백이
                // 눌러도 되는 자리처럼 보입니다.
                expandedInsets: EdgeInsets.zero,
                segments: [
                  for (final vendor in TtsVendor.values)
                    ButtonSegment<TtsVendor>(
                      value: vendor,
                      label: Text(vendor.label),
                    ),
                ],
                selected: {setting.vendor},
                // 저장 중에는 콜백을 통째로 비웁니다. SegmentedButton 은 콜백이
                // 없으면 세그먼트를 비활성으로 그리므로, 잠금과 그 표시가
                // 어긋날 일이 없습니다.
                onSelectionChanged: busy
                    ? null
                    : (values) => _change(context, values.first),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                busy
                    ? '저장하는 중입니다...'
                    : '마지막 변경 ${Formats.dateTime(setting.updatedAt)}',
                style: AppTypography.caption,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _change(BuildContext context, TtsVendor next) async {
    final vm = context.read<TtsVendorViewModel>();
    final ok = await vm.change(next);
    if (!context.mounted) return;
    // **누른 값이 아니라 서버가 돌려준 값**을 말합니다. 둘은 어긋날 수 있고
    // (그 사이 다른 관리자가 바꿨거나, 서버가 다른 값을 확정했거나),
    // 그때 누른 값을 읊으면 화면이 사실이 아닌 것을 확인해 주게 됩니다.
    final applied = vm.setting?.vendor ?? next;
    showResultSnackBar(
      context,
      success: ok,
      // 되돌린 사실을 적습니다. 말없이 되돌리면 눌렀는데 아무 일도 안 일어난
      // 화면으로 보여 같은 것을 몇 번씩 다시 누르게 됩니다.
      message: ok
          ? '바꿨습니다. 지금 합성 엔진은 ${applied.label} 입니다.'
          : '${vm.errorMessage ?? '합성 엔진을 바꾸지 못했습니다.'} 이전 값으로 되돌렸습니다.',
    );
  }
}

/// 키가 없는 벤더로 바꿨을 때 무슨 일이 벌어지는지.
///
/// 조건부가 아니라 늘 띄웁니다. 이 화면은 키가 들어 있는지 알 방법이 없어서
/// "위험할 때만" 을 판단할 수 없습니다.
class _KeyWarning extends StatelessWidget {
  const _KeyWarning();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.warningSurface,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            AppIcons.warning,
            size: AppSizes.icon,
            color: AppColors.warning,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '키가 없는 엔진으로 바꾸면 음성 합성이 통째로 503 으로 멈춥니다',
                  style: AppTypography.bodyStrong,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '본 서버는 다른 엔진으로 대신 넘어가지 않습니다 - 조용히 넘어가면 '
                  '"바꿨는데 목소리가 그대로"가 되어 무엇이 도는 중인지 알 수 없습니다.\n'
                  '키는 여기서 못 바꿉니다. 본 서버(Railway)의 환경변수이고 고치면 재배포해야 합니다. '
                  '이 화면은 키가 들어 있는지 확인하지 못합니다 - 위에 보이는 값이 "합성이 된다"는 뜻은 '
                  '아니니, 바꾸기 전에 환경변수를 직접 확인해 주세요.',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.warningInk,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 벤더별 한 줄 설명. 무엇을 고르는지 모르면 경고만으로는 고를 수 없습니다.
class _VendorGuide extends StatelessWidget {
  const _VendorGuide();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final vendor in TtsVendor.values) ...[
          Text(
            '${vendor.label} · ${vendor.model}',
            style: AppTypography.bodyStrong,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${vendor.description} 환경변수 ${vendor.envKey}',
            style: AppTypography.caption,
          ),
          if (vendor != TtsVendor.values.last)
            const SizedBox(height: AppSpacing.lg),
        ],
      ],
    );
  }
}

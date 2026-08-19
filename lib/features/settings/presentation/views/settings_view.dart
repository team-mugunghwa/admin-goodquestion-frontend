import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_page.dart';
import '../widgets/tts_vendor_section.dart';

/// 서비스 동작을 바꾸는 값들.
///
/// 지금은 음성 합성 하나뿐이지만 섹션을 나란히 세우는 구조로 둡니다. 항목이
/// 늘어날 때 화면을 다시 짜지 않고 [children] 에 카드를 하나 더하면 됩니다.
///
/// 섹션은 각자 자기 값을 불러오고 자기가 저장합니다. 한 화면이 전부를 모아
/// 저장하면 한 항목이 실패했을 때 나머지가 어떻게 됐는지 알 수 없습니다.
class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: '설정',
      description: '고른 값이 바로 저장되고 사용자 앱에 그대로 적용됩니다.',
      child: Center(
        child: ConstrainedBox(
          // 설명이 긴 화면이라 한 줄이 길어지면 읽기 어렵습니다. 편집 폼과 같은
          // 폭에서 자릅니다.
          constraints: const BoxConstraints(maxWidth: AppSizes.formMaxWidth),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TtsVendorSection(),
              // 설정이 늘어나면 여기에
              // `SizedBox(height: AppSpacing.lg)` + 새 섹션을 덧붙입니다.
            ],
          ),
        ),
      ),
    );
  }
}

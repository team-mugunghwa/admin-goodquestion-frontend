import 'package:flutter/material.dart';

import '../constants/app_icons.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// 라벨 + 입력 한 줄.
///
/// `InputDecoration.labelText` 를 쓰지 않는 이유: 뜬 라벨은 값이 들어가면 작아져서
/// 항목이 열 개 넘는 편집 폼에서 훑기 어렵습니다. 라벨을 위에 고정해 두면 어떤
/// 항목이 비었는지 눈으로 훑을 수 있습니다.
class AppField extends StatelessWidget {
  const AppField({
    required this.label,
    required this.child,
    this.hint,
    this.required = false,
    super.key,
  });

  final String label;

  /// 라벨 아래 설명. 값의 뜻이 이름만으로 분명하지 않을 때만 씁니다.
  final String? hint;
  final bool required;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(label, style: AppTypography.bodyStrong),
              if (required)
                Padding(
                  padding: const EdgeInsets.only(left: AppSpacing.xs),
                  child: Text(
                    '*',
                    style: AppTypography.bodyStrong.copyWith(
                      color: AppColors.danger,
                    ),
                  ),
                ),
            ],
          ),
          if (hint != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(hint!, style: AppTypography.caption),
          ],
          const SizedBox(height: AppSpacing.sm),
          child,
        ],
      ),
    );
  }
}

/// 검색 입력.
///
/// 입력할 때마다 서버를 부르지 않습니다. 엔터를 치거나 돋보기를 눌러야 나갑니다 -
/// 관리자 목록 검색은 이름 몇 글자를 치는 동안 대여섯 번의 요청이 나갈 값어치가 없고,
/// 그 사이 목록이 계속 바뀌면 읽기도 어렵습니다.
class AppSearchField extends StatefulWidget {
  const AppSearchField({
    required this.onSubmitted,
    this.hintText = '검색어를 입력하세요',
    this.initialValue,
    this.width = 280,
    super.key,
  });

  final ValueChanged<String> onSubmitted;
  final String hintText;
  final String? initialValue;
  final double width;

  @override
  State<AppSearchField> createState() => _AppSearchFieldState();
}

class _AppSearchFieldState extends State<AppSearchField> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialValue,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      child: TextField(
        controller: _controller,
        onSubmitted: widget.onSubmitted,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: widget.hintText,
          prefixIcon: const Icon(AppIcons.search, size: AppSizes.icon),
          suffixIcon: _controller.text.isEmpty
              ? null
              : IconButton(
                  tooltip: '지우기',
                  icon: const Icon(AppIcons.close, size: AppSizes.icon),
                  onPressed: () {
                    _controller.clear();
                    widget.onSubmitted('');
                    setState(() {});
                  },
                ),
        ),
        onChanged: (_) => setState(() {}),
      ),
    );
  }
}

/// 목록 상단의 필터 줄. 검색과 상태 필터를 나란히 둡니다.
class AppFilterBar extends StatelessWidget {
  const AppFilterBar({required this.children, super.key});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Wrap(
        spacing: AppSpacing.md,
        runSpacing: AppSpacing.md,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: children,
      ),
    );
  }
}

/// 필터용 드롭다운. 값이 null 이면 "전체".
class AppFilterDropdown<T> extends StatelessWidget {
  const AppFilterDropdown({
    required this.value,
    required this.items,
    required this.onChanged,
    required this.allLabel,
    this.width = 160,
    super.key,
  });

  final T? value;
  final Map<T, String> items;
  final ValueChanged<T?> onChanged;

  /// null 을 골랐을 때의 이름. "전체 상태"처럼 무엇의 전체인지 적습니다.
  final String allLabel;
  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: DropdownButtonFormField<T?>(
        initialValue: value,
        isExpanded: true,
        style: AppTypography.body,
        items: [
          DropdownMenuItem<T?>(value: null, child: Text(allLabel)),
          for (final entry in items.entries)
            DropdownMenuItem<T?>(value: entry.key, child: Text(entry.value)),
        ],
        onChanged: onChanged,
      ),
    );
  }
}

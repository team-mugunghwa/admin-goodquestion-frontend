import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// 되돌릴 수 없는 조작 전에 한 번 묻습니다.
///
/// 삭제, 정지, 로그인 세션 종료가 대상입니다. **저장에는 쓰지 마세요** — 저장은
/// 되돌릴 수 있고, 매번 확인을 받으면 사람이 내용을 읽지 않고 누르게 됩니다.
/// 확인 창이 늘어날수록 정작 위험한 것에서도 그냥 누르게 됩니다.
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = '확인',
  String cancelLabel = '취소',
  bool destructive = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Text(message),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(cancelLabel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: destructive
              ? FilledButton.styleFrom(backgroundColor: AppColors.danger)
              : null,
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// 한 줄을 입력받는 대화상자. 정지 사유처럼 이유를 함께 받아야 하는 조작에 씁니다.
///
/// @return 입력값. 취소하면 null.
Future<String?> showPromptDialog(
  BuildContext context, {
  required String title,
  required String label,
  String? message,
  String confirmLabel = '확인',
  int maxLines = 3,
}) {
  final controller = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message != null) ...[
              Text(message),
              const SizedBox(height: AppSpacing.lg),
            ],
            TextField(
              controller: controller,
              autofocus: true,
              maxLines: maxLines,
              decoration: InputDecoration(hintText: label),
            ),
          ],
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
            final value = controller.text.trim();
            // 빈 값으로 확인을 누르면 아무 일도 하지 않습니다. 사유가 비면
            // 나중에 왜 막았는지 아무도 모릅니다.
            if (value.isEmpty) return;
            Navigator.of(context).pop(value);
          },
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
}

/// 조작 결과를 알립니다.
///
/// 성공은 짧게, 실패는 길게 띄웁니다 — 실패 메시지는 읽고 조치해야 하는 글입니다.
void showResultSnackBar(
  BuildContext context, {
  required bool success,
  required String message,
}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success ? AppColors.ink900 : AppColors.danger,
        duration: Duration(seconds: success ? 2 : 5),
      ),
    );
}

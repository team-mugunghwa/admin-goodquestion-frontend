import 'package:flutter/material.dart';

import '../../../../core/domain/content_status.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_form.dart';
import '../../domain/entities/guide.dart';

/// 이용안내 편집 결과.
class GuideDraft {
  const GuideDraft({
    required this.category,
    required this.title,
    required this.content,
    required this.status,
  });

  final GuideCategory category;
  final String title;
  final String content;
  final ContentStatus status;
}

/// 이용안내를 대화상자에서 편집합니다.
///
/// 공지와 달리 별도 화면을 만들지 않았습니다. 이용안내는 순서가 중요해서 목록을
/// 보면서 고치는 일이 많은데, 화면을 옮겨 다니면 방금 어디를 고쳤는지 놓칩니다.
///
/// @return 저장할 내용. 취소하면 null.
Future<GuideDraft?> showGuideEditDialog(
  BuildContext context, {
  Guide? guide,
  GuideCategory? defaultCategory,
}) {
  final titleController = TextEditingController(text: guide?.title);
  final contentController = TextEditingController(text: guide?.content);
  var category = guide?.category ?? defaultCategory ?? GuideCategory.basic;
  var status = guide?.status ?? ContentStatus.draft;
  final formKey = GlobalKey<FormState>();

  return showDialog<GuideDraft>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text(guide == null ? '이용안내 추가' : '이용안내 수정'),
        content: SizedBox(
          width: 560,
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppField(
                    label: '제목',
                    required: true,
                    hint: '사용자가 목록에서 보는 질문 형태로 적으면 찾기 쉽습니다.',
                    child: TextFormField(
                      controller: titleController,
                      autofocus: true,
                      decoration: const InputDecoration(
                        hintText: '예: 아이 목소리가 잘 인식되지 않아요',
                      ),
                      validator: (value) =>
                          (value == null || value.trim().isEmpty)
                          ? '제목을 입력해 주세요.'
                          : null,
                    ),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: AppField(
                          label: '분류',
                          child: DropdownButtonFormField<GuideCategory>(
                            initialValue: category,
                            items: [
                              for (final entry in GuideCategory.labels.entries)
                                DropdownMenuItem(
                                  value: entry.key,
                                  child: Text(entry.value),
                                ),
                            ],
                            onChanged: (value) =>
                                setState(() => category = value ?? category),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.lg),
                      Expanded(
                        child: AppField(
                          label: '노출 상태',
                          child: DropdownButtonFormField<ContentStatus>(
                            initialValue: status,
                            items: [
                              for (final entry in ContentStatus.labels.entries)
                                DropdownMenuItem(
                                  value: entry.key,
                                  child: Text(entry.value),
                                ),
                            ],
                            onChanged: (value) =>
                                setState(() => status = value ?? status),
                          ),
                        ),
                      ),
                    ],
                  ),
                  AppField(
                    label: '본문',
                    required: true,
                    child: TextFormField(
                      controller: contentController,
                      maxLines: 10,
                      minLines: 6,
                      validator: (value) =>
                          (value == null || value.trim().isEmpty)
                          ? '본문을 입력해 주세요.'
                          : null,
                    ),
                  ),
                ],
              ),
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
                GuideDraft(
                  category: category,
                  title: titleController.text.trim(),
                  content: contentController.text,
                  status: status,
                ),
              );
            },
            child: const Text('저장'),
          ),
        ],
      ),
    ),
  );
}

import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_form.dart';
import '../../domain/entities/story.dart';

class CharacterDraft {
  const CharacterDraft({
    required this.characterKey,
    required this.name,
    required this.personality,
    this.guidanceStyle,
    this.ttsVoice,
    this.ttsStyle,
    this.expressionKeys = const [],
  });

  final String characterKey;
  final String name;
  final String personality;
  final String? guidanceStyle;
  final String? ttsVoice;
  final String? ttsStyle;
  final List<String> expressionKeys;
}

/// 캐릭터를 편집합니다.
Future<CharacterDraft?> showCharacterEditDialog(
  BuildContext context, {
  StoryCharacter? character,
}) {
  final formKey = GlobalKey<FormState>();
  final keyController = TextEditingController(text: character?.characterKey);
  final nameController = TextEditingController(text: character?.name);
  final personalityController = TextEditingController(
    text: character?.personality,
  );
  final guidanceController = TextEditingController(
    text: character?.guidanceStyle,
  );
  final voiceController = TextEditingController(text: character?.ttsVoice);
  final styleController = TextEditingController(text: character?.ttsStyle);
  final expressionsController = TextEditingController(
    text: character?.expressionKeys.join(', '),
  );

  return showDialog<CharacterDraft>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(character == null ? '캐릭터 추가' : '캐릭터 수정'),
      content: SizedBox(
        width: 600,
        child: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: AppField(
                        label: '표시 이름',
                        required: true,
                        child: TextFormField(
                          controller: nameController,
                          decoration: const InputDecoration(
                            hintText: '예: 방귀쟁이 며느리',
                          ),
                          validator: (value) =>
                              (value == null || value.trim().isEmpty)
                              ? '이름을 입력해 주세요.'
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(
                      child: AppField(
                        label: '캐릭터 키',
                        required: true,
                        hint: '표정 이미지 파일명의 앞부분입니다. 바꾸면 올려 둔 이미지가 안 붙습니다.',
                        child: TextFormField(
                          controller: keyController,
                          decoration: const InputDecoration(
                            hintText: '예: banggui',
                          ),
                          validator: (value) =>
                              (value == null || value.trim().isEmpty)
                              ? '캐릭터 키를 입력해 주세요.'
                              : null,
                        ),
                      ),
                    ),
                  ],
                ),
                AppField(
                  label: '성격과 말투',
                  required: true,
                  hint: '캐릭터 대사를 만드는 모델이 그대로 참고합니다. 구체적으로 적을수록 일관됩니다.',
                  child: TextFormField(
                    controller: personalityController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: '예: 조심스럽고 부끄러움이 많지만 따뜻한 젊은 여성. '
                          '미안해하면서도 다정하게 말한다.',
                    ),
                    validator: (value) =>
                        (value == null || value.trim().isEmpty)
                        ? '성격과 말투를 입력해 주세요.'
                        : null,
                  ),
                ),
                AppField(
                  label: '유도 방식',
                  hint: '아이가 막혔을 때 이 캐릭터가 어떻게 도와주는지.',
                  child: TextFormField(
                    controller: guidanceController,
                    maxLines: 3,
                  ),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: AppField(
                        label: '음성(보이스) 이름',
                        hint: '합성에 쓰는 보이스 식별자입니다.',
                        child: TextFormField(
                          controller: voiceController,
                          decoration: const InputDecoration(hintText: '예: Leda'),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(
                      child: AppField(
                        label: '표정 키 목록',
                        hint: '쉼표로 구분합니다. 없는 표정을 요구하면 기본 표정으로 대체됩니다.',
                        child: TextFormField(
                          controller: expressionsController,
                          decoration: const InputDecoration(
                            hintText: 'idle, happy, worried',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                AppField(
                  label: '연기 지시문',
                  // 실제로 겪은 문제라 안내를 남겨 둡니다.
                  hint: '성별과 연령을 반드시 적으세요. 보이스 이름만으로는 성별이 정해지지 않아, '
                      '같은 보이스가 지시문에 따라 남성으로도 여성으로도 나옵니다.',
                  child: TextFormField(
                    controller: styleController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: '예: 젊은 여자 목소리로. 부끄러움이 많고 조심스러운 사람이 '
                          '걱정스럽게 속마음을 털어놓듯, 작고 조심스럽게 말해줘:',
                    ),
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
              CharacterDraft(
                characterKey: keyController.text.trim(),
                name: nameController.text.trim(),
                personality: personalityController.text.trim(),
                guidanceStyle: _orNull(guidanceController.text),
                ttsVoice: _orNull(voiceController.text),
                ttsStyle: _orNull(styleController.text),
                expressionKeys: expressionsController.text
                    .split(',')
                    .map((value) => value.trim())
                    .where((value) => value.isNotEmpty)
                    .toList(),
              ),
            );
          },
          child: const Text('저장'),
        ),
      ],
    ),
  );
}

String? _orNull(String value) => value.trim().isEmpty ? null : value.trim();

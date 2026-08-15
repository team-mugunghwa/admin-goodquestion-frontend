import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_form.dart';
import '../../domain/entities/story.dart';

/// 장면 편집 결과.
class SceneDraft {
  const SceneDraft({
    required this.sceneType,
    required this.sceneDescription,
    this.characterId,
    this.characterName,
    this.characterOpening,
    this.characterClosing,
    this.sceneGoal,
    this.requiredElements = const [],
    this.preferredTurns,
    this.maxTurns,
  });

  final SceneType sceneType;
  final String sceneDescription;
  final String? characterId;
  final String? characterName;
  final String? characterOpening;
  final String? characterClosing;
  final String? sceneGoal;
  final List<String> requiredElements;
  final int? preferredTurns;
  final int? maxTurns;
}

/// 아이가 말할 때 확인하는 생각 요소. 서버의 `ThinkingElement` 와 값이 같아야 합니다.
const Map<String, String> _thinkingElements = {
  'DECISION': '선택',
  'REASON': '이유',
  'PERSPECTIVE': '상대 입장',
  'SOLUTION': '해결 방법',
  'RESULT': '결과 예상',
  'EMOTION': '감정',
  'EMPATHY': '공감',
  'REQUEST': '부탁',
};

/// 장면을 편집합니다.
///
/// 내레이션 장면과 대화 장면의 입력 항목이 크게 다릅니다. 대화 장면은 캐릭터,
/// 첫 대사, 장면 목표, 턴 수가 모두 있어야 서비스가 실행할 수 있어서, 유형을
/// 대화로 고르는 순간 그 항목들이 나타나고 필수가 됩니다.
Future<SceneDraft?> showSceneEditDialog(
  BuildContext context, {
  StoryScene? scene,
  required List<StoryCharacter> characters,
}) {
  final formKey = GlobalKey<FormState>();
  final descriptionController = TextEditingController(
    text: scene?.sceneDescription,
  );
  final openingController = TextEditingController(text: scene?.characterOpening);
  final closingController = TextEditingController(text: scene?.characterClosing);
  final goalController = TextEditingController(text: scene?.sceneGoal);
  final preferredController = TextEditingController(
    text: scene?.preferredTurns?.toString() ?? '3',
  );
  final maxController = TextEditingController(
    text: scene?.maxTurns?.toString() ?? '5',
  );

  var sceneType = scene?.sceneType ?? SceneType.story;
  var characterId = scene?.characterId;
  var selectedElements = <String>{...scene?.requiredElements ?? const []};

  return showDialog<SceneDraft>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) {
        final isDialogue = sceneType == SceneType.dialogue;
        return AlertDialog(
          title: Text(scene == null ? '장면 추가' : '장면 수정'),
          content: SizedBox(
            width: 640,
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppField(
                      label: '장면 유형',
                      hint: '내레이션은 듣기만 하고, 대화는 아이가 말합니다.',
                      child: SegmentedButton<SceneType>(
                        segments: const [
                          ButtonSegment(
                            value: SceneType.story,
                            label: Text('내레이션'),
                          ),
                          ButtonSegment(
                            value: SceneType.dialogue,
                            label: Text('대화'),
                          ),
                        ],
                        selected: {sceneType},
                        onSelectionChanged: (values) =>
                            setState(() => sceneType = values.first),
                      ),
                    ),
                    AppField(
                      label: isDialogue ? '장면 상황' : '내레이션 본문',
                      required: true,
                      hint: isDialogue
                          ? '대화가 벌어지는 상황을 적습니다. 발화를 분석할 때 맥락으로 쓰입니다.'
                          : '아이에게 그대로 들려줄 문장입니다.',
                      child: TextFormField(
                        controller: descriptionController,
                        maxLines: 5,
                        minLines: 3,
                        validator: (value) =>
                            (value == null || value.trim().isEmpty)
                            ? '내용을 입력해 주세요.'
                            : null,
                      ),
                    ),

                    if (isDialogue) ...[
                      AppField(
                        label: '캐릭터',
                        required: true,
                        hint: characters.isEmpty
                            ? '먼저 캐릭터 탭에서 캐릭터를 만들어 주세요.'
                            : '이 장면에서 아이와 대화할 캐릭터입니다.',
                        child: DropdownButtonFormField<String>(
                          initialValue: characters.any((c) => c.id == characterId)
                              ? characterId
                              : null,
                          items: [
                            for (final character in characters)
                              DropdownMenuItem(
                                value: character.id,
                                child: Text(character.name),
                              ),
                          ],
                          onChanged: (value) =>
                              setState(() => characterId = value),
                          validator: (value) =>
                              value == null ? '캐릭터를 골라 주세요.' : null,
                        ),
                      ),
                      AppField(
                        label: '캐릭터 첫 대사',
                        required: true,
                        hint: '장면이 시작될 때 캐릭터가 먼저 건네는 말입니다.',
                        child: TextFormField(
                          controller: openingController,
                          maxLines: 3,
                          validator: (value) =>
                              (value == null || value.trim().isEmpty)
                              ? '첫 대사를 입력해 주세요.'
                              : null,
                        ),
                      ),
                      AppField(
                        label: '장면 목표',
                        required: true,
                        hint: '이 장면에서 아이가 말해 봤으면 하는 것.',
                        child: TextFormField(
                          controller: goalController,
                          maxLines: 2,
                          validator: (value) =>
                              (value == null || value.trim().isEmpty)
                              ? '장면 목표를 입력해 주세요.'
                              : null,
                        ),
                      ),
                      AppField(
                        label: '확인할 생각 요소',
                        required: true,
                        hint: '아이 발화에서 이 요소들이 나오면 장면 목표를 채운 것으로 봅니다.',
                        child: Wrap(
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.sm,
                          children: [
                            for (final entry in _thinkingElements.entries)
                              FilterChip(
                                label: Text(entry.value),
                                selected: selectedElements.contains(entry.key),
                                onSelected: (selected) => setState(() {
                                  selected
                                      ? selectedElements.add(entry.key)
                                      : selectedElements.remove(entry.key);
                                }),
                              ),
                          ],
                        ),
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: AppField(
                              label: '적정 턴 수',
                              hint: '이만큼 말하면 목표를 채운 것으로 봅니다.',
                              child: TextFormField(
                                controller: preferredController,
                                keyboardType: TextInputType.number,
                                validator: _turnValidator,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.lg),
                          Expanded(
                            child: AppField(
                              label: '최대 턴 수',
                              hint: '여기 닿으면 목표와 무관하게 장면을 닫습니다.',
                              child: TextFormField(
                                controller: maxController,
                                keyboardType: TextInputType.number,
                                validator: _turnValidator,
                              ),
                            ),
                          ),
                        ],
                      ),
                      AppField(
                        label: '마지막 고정 대사',
                        hint: '장면을 닫을 때 캐릭터가 하는 말. 비우면 매번 새로 만듭니다.',
                        child: TextFormField(
                          controller: closingController,
                          maxLines: 2,
                        ),
                      ),
                    ],
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
                if (isDialogue && selectedElements.isEmpty) {
                  // 요소가 하나도 없으면 서버가 장면 목표를 판정할 수 없습니다.
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('확인할 생각 요소를 하나 이상 골라 주세요.')),
                  );
                  return;
                }
                final preferred = int.tryParse(preferredController.text);
                final max = int.tryParse(maxController.text);
                if (isDialogue &&
                    preferred != null &&
                    max != null &&
                    preferred > max) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('적정 턴 수는 최대 턴 수보다 클 수 없습니다.')),
                  );
                  return;
                }

                final character = characters
                    .where((c) => c.id == characterId)
                    .firstOrNull;
                Navigator.of(context).pop(
                  SceneDraft(
                    sceneType: sceneType,
                    sceneDescription: descriptionController.text.trim(),
                    characterId: isDialogue ? characterId : null,
                    // 서버는 표시용 이름을 따로 들고 있습니다. 캐릭터를 고른 순간
                    // 그 이름으로 맞춰 보내면 화면과 어긋날 일이 없습니다.
                    characterName: isDialogue ? character?.name : null,
                    characterOpening: isDialogue
                        ? openingController.text.trim()
                        : null,
                    characterClosing: isDialogue &&
                            closingController.text.trim().isNotEmpty
                        ? closingController.text.trim()
                        : null,
                    sceneGoal: isDialogue ? goalController.text.trim() : null,
                    requiredElements: isDialogue
                        ? selectedElements.toList()
                        : const [],
                    preferredTurns: isDialogue ? preferred : null,
                    maxTurns: isDialogue ? max : null,
                  ),
                );
              },
              child: const Text('저장'),
            ),
          ],
        );
      },
    ),
  );
}

String? _turnValidator(String? value) {
  final parsed = int.tryParse(value ?? '');
  if (parsed == null || parsed <= 0) return '1 이상의 숫자를 입력해 주세요.';
  return null;
}

/// 장면 목록의 한 줄에 쓰는 요약 문장.
String sceneSubtitle(StoryScene scene) {
  if (!scene.isDialogue) return '내레이션';
  final elements = scene.requiredElements
      .map((code) => _thinkingElements[code] ?? code)
      .join(', ');
  return '${scene.characterName ?? "캐릭터 없음"} · '
      '${scene.preferredTurns ?? "-"}~${scene.maxTurns ?? "-"}턴'
      '${elements.isEmpty ? "" : " · $elements"}';
}

/// 장면 목록에서 유형을 구분하는 배지 색.
Color sceneTypeColor(StoryScene scene) =>
    scene.isDialogue ? AppColors.primary : AppColors.ink500;

/// 목록에서 쓰는 유형 이름.
TextStyle sceneTypeStyle(StoryScene scene) =>
    AppTypography.badge.copyWith(color: sceneTypeColor(scene));

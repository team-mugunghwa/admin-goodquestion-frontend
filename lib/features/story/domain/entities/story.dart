import '../../../../core/widgets/app_status_chip.dart';

enum StoryStatus {
  draft('DRAFT', '작성 중', StatusTone.neutral),
  published('PUBLISHED', '공개', StatusTone.positive),
  archived('ARCHIVED', '보관', StatusTone.caution);

  const StoryStatus(this.code, this.label, this.tone);

  final String code;
  final String label;
  final StatusTone tone;

  static StoryStatus fromCode(String? code) => StoryStatus.values.firstWhere(
    (status) => status.code == code,
    orElse: () => StoryStatus.draft,
  );

  static Map<StoryStatus, String> get labels => {
    for (final status in StoryStatus.values) status: status.label,
  };
}

enum SceneType {
  story('STORY', '내레이션'),
  dialogue('DIALOGUE', '대화');

  const SceneType(this.code, this.label);

  final String code;
  final String label;

  static SceneType fromCode(String? code) => SceneType.values
      .firstWhere((type) => type.code == code, orElse: () => SceneType.story);
}

class StorySummary {
  const StorySummary({
    required this.id,
    required this.title,
    required this.summary,
    required this.difficulty,
    required this.status,
    required this.topics,
    required this.sceneCount,
    this.estimatedMinutes,
    this.imageUrl,
    this.updatedAt,
  });

  final String id;
  final String title;
  final String summary;
  final String difficulty;
  final StoryStatus status;
  final List<String> topics;

  /// 장면 수. 0인 이야기는 공개할 수 없습니다.
  final int sceneCount;
  final int? estimatedMinutes;
  final String? imageUrl;
  final DateTime? updatedAt;
}

class StoryDetail {
  const StoryDetail({
    required this.id,
    required this.title,
    required this.summary,
    required this.difficulty,
    required this.status,
    required this.topics,
    required this.sceneCount,
    required this.sessionCount,
    this.childRole,
    this.intro,
    this.imageUrl,
    this.estimatedMinutes,
    this.updatedAt,
  });

  final String id;
  final String title;
  final String summary;
  final String? childRole;
  final String? intro;
  final String? imageUrl;
  final String difficulty;
  final int? estimatedMinutes;
  final StoryStatus status;
  final List<String> topics;
  final int sceneCount;

  /// 이 이야기로 시작된 학습 세션 수. 0보다 크면 삭제할 수 없습니다.
  final int sessionCount;
  final DateTime? updatedAt;

  bool get deletable => sessionCount == 0;
}

class StoryScene {
  const StoryScene({
    required this.id,
    required this.sceneOrder,
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
    this.imageUrl,
  });

  final String id;
  final int sceneOrder;
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
  final String? imageUrl;

  bool get isDialogue => sceneType == SceneType.dialogue;
}

class StoryCharacter {
  const StoryCharacter({
    required this.id,
    required this.characterKey,
    required this.name,
    required this.personality,
    this.guidanceStyle,
    this.ttsVoice,
    this.ttsStyle,
    this.expressionKeys = const [],
  });

  final String id;

  /// 표정 이미지 파일명의 앞부분. 바꾸면 이미 올라간 이미지가 안 붙습니다.
  final String characterKey;
  final String name;
  final String personality;
  final String? guidanceStyle;
  final String? ttsVoice;
  final String? ttsStyle;
  final List<String> expressionKeys;
}

class Topic {
  const Topic({
    required this.id,
    required this.name,
    required this.displayOrder,
  });

  final String id;
  final String name;
  final int displayOrder;
}

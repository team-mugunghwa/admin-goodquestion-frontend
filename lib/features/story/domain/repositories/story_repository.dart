import '../../../../core/network/page_result.dart';
import '../entities/story.dart';

abstract class StoryRepository {
  Future<PageResult<StorySummary>> getStories({
    StoryStatus? status,
    String? keyword,
    int page = 0,
    int size = 20,
  });

  Future<StoryDetail> getStory(String storyId);

  Future<StoryDetail> createStory({
    required String title,
    required String summary,
    String? childRole,
    String? intro,
    String? imageUrl,
    String? difficulty,
    int? estimatedMinutes,
    StoryStatus? status,
    List<String>? topics,
  });

  /// null 인 항목은 건드리지 않습니다. [topics] 만 예외로, 빈 배열이면 전부 지웁니다.
  Future<StoryDetail> updateStory({
    required String storyId,
    String? title,
    String? summary,
    String? childRole,
    String? intro,
    String? imageUrl,
    String? difficulty,
    int? estimatedMinutes,
    StoryStatus? status,
    List<String>? topics,
  });

  /// 진행 기록이 있으면 서버가 거절합니다(`STORY_IN_USE`).
  Future<void> deleteStory(String storyId);

  // ---- 장면 ----

  Future<List<StoryScene>> getScenes(String storyId);

  Future<StoryScene> createScene({
    required String storyId,
    required SceneType sceneType,
    required String sceneDescription,
    String? imageUrl,
    String? characterId,
    String? characterName,
    String? characterOpening,
    String? characterClosing,
    String? sceneGoal,
    List<String>? requiredElements,
    int? preferredTurns,
    int? maxTurns,
  });

  Future<StoryScene> updateScene({
    required String storyId,
    required String sceneId,
    SceneType? sceneType,
    String? sceneDescription,
    String? imageUrl,
    String? characterId,
    String? characterName,
    String? characterOpening,
    String? characterClosing,
    String? sceneGoal,
    List<String>? requiredElements,
    int? preferredTurns,
    int? maxTurns,
  });

  Future<List<StoryScene>> reorderScenes({
    required String storyId,
    required List<String> sceneIds,
  });

  Future<void> deleteScene({required String storyId, required String sceneId});

  // ---- 캐릭터 ----

  Future<List<StoryCharacter>> getCharacters(String storyId);

  Future<StoryCharacter> saveCharacter({
    required String storyId,
    String? characterId,
    required String characterKey,
    required String name,
    required String personality,
    String? guidanceStyle,
    String? ttsVoice,
    String? ttsStyle,
    List<String>? expressionKeys,
  });

  Future<void> deleteCharacter({
    required String storyId,
    required String characterId,
  });

  // ---- 주제 ----

  Future<List<Topic>> getTopics();
}

import '../../../../core/network/page_result.dart';
import '../entities/story.dart';
import '../repositories/story_repository.dart';

/// 이야기 관리 UseCase 모음.
///
/// 이야기 / 장면 / 캐릭터 / 주제 네 갈래를 한 파일에 둡니다. 넷이 항상 같은
/// 화면에서 함께 쓰이므로 나눠도 결국 넷을 다 열게 됩니다.

class GetStoriesUseCase {
  const GetStoriesUseCase(this._repository);
  final StoryRepository _repository;

  Future<PageResult<StorySummary>> call({
    StoryStatus? status,
    String? keyword,
    int page = 0,
    int size = 20,
  }) => _repository.getStories(
    status: status,
    keyword: keyword,
    page: page,
    size: size,
  );
}

class GetStoryUseCase {
  const GetStoryUseCase(this._repository);
  final StoryRepository _repository;

  Future<StoryDetail> call(String storyId) => _repository.getStory(storyId);
}

class SaveStoryUseCase {
  const SaveStoryUseCase(this._repository);
  final StoryRepository _repository;

  /// [storyId] 가 null 이면 새로 만들고, 있으면 고칩니다.
  Future<StoryDetail> call({
    String? storyId,
    required String title,
    required String summary,
    String? childRole,
    String? intro,
    String? imageUrl,
    String? difficulty,
    int? estimatedMinutes,
    StoryStatus? status,
    List<String>? topics,
  }) => storyId == null
      ? _repository.createStory(
          title: title,
          summary: summary,
          childRole: childRole,
          intro: intro,
          imageUrl: imageUrl,
          difficulty: difficulty,
          estimatedMinutes: estimatedMinutes,
          status: status,
          topics: topics,
        )
      : _repository.updateStory(
          storyId: storyId,
          title: title,
          summary: summary,
          childRole: childRole,
          intro: intro,
          imageUrl: imageUrl,
          difficulty: difficulty,
          estimatedMinutes: estimatedMinutes,
          status: status,
          topics: topics,
        );
}

class DeleteStoryUseCase {
  const DeleteStoryUseCase(this._repository);
  final StoryRepository _repository;

  Future<void> call(String storyId) => _repository.deleteStory(storyId);
}

class GetScenesUseCase {
  const GetScenesUseCase(this._repository);
  final StoryRepository _repository;

  Future<List<StoryScene>> call(String storyId) =>
      _repository.getScenes(storyId);
}

class SaveSceneUseCase {
  const SaveSceneUseCase(this._repository);
  final StoryRepository _repository;

  Future<StoryScene> call({
    required String storyId,
    String? sceneId,
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
  }) => sceneId == null
      ? _repository.createScene(
          storyId: storyId,
          sceneType: sceneType,
          sceneDescription: sceneDescription,
          imageUrl: imageUrl,
          characterId: characterId,
          characterName: characterName,
          characterOpening: characterOpening,
          characterClosing: characterClosing,
          sceneGoal: sceneGoal,
          requiredElements: requiredElements,
          preferredTurns: preferredTurns,
          maxTurns: maxTurns,
        )
      : _repository.updateScene(
          storyId: storyId,
          sceneId: sceneId,
          sceneType: sceneType,
          sceneDescription: sceneDescription,
          imageUrl: imageUrl,
          characterId: characterId,
          characterName: characterName,
          characterOpening: characterOpening,
          characterClosing: characterClosing,
          sceneGoal: sceneGoal,
          requiredElements: requiredElements,
          preferredTurns: preferredTurns,
          maxTurns: maxTurns,
        );
}

class ReorderScenesUseCase {
  const ReorderScenesUseCase(this._repository);
  final StoryRepository _repository;

  Future<List<StoryScene>> call({
    required String storyId,
    required List<String> sceneIds,
  }) => _repository.reorderScenes(storyId: storyId, sceneIds: sceneIds);
}

class DeleteSceneUseCase {
  const DeleteSceneUseCase(this._repository);
  final StoryRepository _repository;

  Future<void> call({required String storyId, required String sceneId}) =>
      _repository.deleteScene(storyId: storyId, sceneId: sceneId);
}

class GetCharactersUseCase {
  const GetCharactersUseCase(this._repository);
  final StoryRepository _repository;

  Future<List<StoryCharacter>> call(String storyId) =>
      _repository.getCharacters(storyId);
}

class SaveCharacterUseCase {
  const SaveCharacterUseCase(this._repository);
  final StoryRepository _repository;

  Future<StoryCharacter> call({
    required String storyId,
    String? characterId,
    required String characterKey,
    required String name,
    required String personality,
    String? guidanceStyle,
    String? ttsVoice,
    String? ttsStyle,
    List<String>? expressionKeys,
  }) => _repository.saveCharacter(
    storyId: storyId,
    characterId: characterId,
    characterKey: characterKey,
    name: name,
    personality: personality,
    guidanceStyle: guidanceStyle,
    ttsVoice: ttsVoice,
    ttsStyle: ttsStyle,
    expressionKeys: expressionKeys,
  );
}

class DeleteCharacterUseCase {
  const DeleteCharacterUseCase(this._repository);
  final StoryRepository _repository;

  Future<void> call({required String storyId, required String characterId}) =>
      _repository.deleteCharacter(storyId: storyId, characterId: characterId);
}

class GetTopicsUseCase {
  const GetTopicsUseCase(this._repository);
  final StoryRepository _repository;

  Future<List<Topic>> call() => _repository.getTopics();
}

import '../../../../core/presentation/base_view_model.dart';
import '../../domain/entities/story.dart';
import '../../domain/usecases/story_use_cases.dart';

/// 이야기 편집 화면의 상태. 이야기 본문, 장면, 캐릭터를 한 화면에서 다룹니다.
///
/// 셋을 나누지 않은 이유: 장면을 만들려면 캐릭터가 있어야 하고, 캐릭터를 지우려면
/// 그 캐릭터를 쓰는 장면이 없어야 합니다. 서로를 보면서 편집하는 일이라 화면을
/// 나누면 계속 오가게 됩니다.
class StoryEditViewModel extends BaseViewModel {
  StoryEditViewModel({
    required GetStoryUseCase getStory,
    required SaveStoryUseCase saveStory,
    required GetScenesUseCase getScenes,
    required SaveSceneUseCase saveScene,
    required ReorderScenesUseCase reorderScenes,
    required DeleteSceneUseCase deleteScene,
    required GetCharactersUseCase getCharacters,
    required SaveCharacterUseCase saveCharacter,
    required DeleteCharacterUseCase deleteCharacter,
    required GetTopicsUseCase getTopics,
    this.storyId,
  }) : _getStory = getStory,
       _saveStory = saveStory,
       _getScenes = getScenes,
       _saveScene = saveScene,
       _reorderScenes = reorderScenes,
       _deleteScene = deleteScene,
       _getCharacters = getCharacters,
       _saveCharacter = saveCharacter,
       _deleteCharacter = deleteCharacter,
       _getTopics = getTopics;

  final GetStoryUseCase _getStory;
  final SaveStoryUseCase _saveStory;
  final GetScenesUseCase _getScenes;
  final SaveSceneUseCase _saveScene;
  final ReorderScenesUseCase _reorderScenes;
  final DeleteSceneUseCase _deleteScene;
  final GetCharactersUseCase _getCharacters;
  final SaveCharacterUseCase _saveCharacter;
  final DeleteCharacterUseCase _deleteCharacter;
  final GetTopicsUseCase _getTopics;

  /// null 이면 새 이야기입니다.
  String? storyId;

  StoryDetail? _story;
  List<StoryScene> _scenes = const [];
  List<StoryCharacter> _characters = const [];
  List<Topic> _topics = const [];
  StoryStatus _status = StoryStatus.draft;
  List<String> _selectedTopics = const [];

  StoryDetail? get story => _story;
  List<StoryScene> get scenes => _scenes;
  List<StoryCharacter> get characters => _characters;
  List<Topic> get topics => _topics;
  StoryStatus get status => _status;
  List<String> get selectedTopics => _selectedTopics;
  bool get isNew => storyId == null;

  /// 장면이 없으면 공개할 수 없습니다. 서버도 막지만 화면에서 미리 알려 줍니다 —
  /// 저장을 눌러 오류를 보고 나서야 아는 것보다 낫습니다.
  bool get canPublish => _scenes.isNotEmpty;

  Future<void> load() => guard(() async {
    // 주제 목록은 새 이야기에서도 필요합니다.
    _topics = await _getTopics();
    if (storyId == null) return;

    final results = await Future.wait([
      _getStory(storyId!),
      _getScenes(storyId!),
      _getCharacters(storyId!),
    ]);
    _story = results[0] as StoryDetail;
    _scenes = results[1] as List<StoryScene>;
    _characters = results[2] as List<StoryCharacter>;
    _status = _story!.status;
    _selectedTopics = _story!.topics;
  });

  void changeStatus(StoryStatus status) {
    _status = status;
    safeNotify();
  }

  void changeTopics(List<String> topics) {
    _selectedTopics = topics;
    safeNotify();
  }

  Future<StoryDetail?> saveStory({
    required String title,
    required String summary,
    String? childRole,
    String? intro,
    String? imageUrl,
    String? difficulty,
    int? estimatedMinutes,
  }) async {
    StoryDetail? saved;
    final ok = await runTask(() async {
      saved = await _saveStory(
        storyId: storyId,
        title: title,
        summary: summary,
        childRole: childRole,
        intro: intro,
        imageUrl: imageUrl,
        difficulty: difficulty,
        estimatedMinutes: estimatedMinutes,
        status: _status,
        topics: _selectedTopics,
      );
      _story = saved;
      // 새 이야기였다면 이제 id 가 생겼습니다. 장면과 캐릭터를 여기에 붙일 수 있습니다.
      storyId ??= saved!.id;
    });
    return ok ? saved : null;
  }

  Future<bool> saveScene({
    String? sceneId,
    required SceneType sceneType,
    required String sceneDescription,
    String? characterId,
    String? characterName,
    String? characterOpening,
    String? characterClosing,
    String? sceneGoal,
    List<String>? requiredElements,
    int? preferredTurns,
    int? maxTurns,
  }) async {
    if (storyId == null) return false;
    final ok = await runTask(
      () => _saveScene(
        storyId: storyId!,
        sceneId: sceneId,
        sceneType: sceneType,
        sceneDescription: sceneDescription,
        characterId: characterId,
        characterName: characterName,
        characterOpening: characterOpening,
        characterClosing: characterClosing,
        sceneGoal: sceneGoal,
        requiredElements: requiredElements,
        preferredTurns: preferredTurns,
        maxTurns: maxTurns,
      ),
    );
    if (ok) await _refreshScenes();
    return ok;
  }

  Future<bool> reorderScenes(List<String> sceneIds) async {
    if (storyId == null) return false;
    final ok = await runTask(() async {
      _scenes = await _reorderScenes(storyId: storyId!, sceneIds: sceneIds);
    });
    if (!ok) await _refreshScenes();
    return ok;
  }

  Future<bool> deleteScene(String sceneId) async {
    if (storyId == null) return false;
    final ok = await runTask(
      () => _deleteScene(storyId: storyId!, sceneId: sceneId),
    );
    if (ok) await _refreshScenes();
    return ok;
  }

  Future<bool> saveCharacter({
    String? characterId,
    required String characterKey,
    required String name,
    required String personality,
    String? guidanceStyle,
    String? ttsVoice,
    String? ttsStyle,
    List<String>? expressionKeys,
  }) async {
    if (storyId == null) return false;
    final ok = await runTask(
      () => _saveCharacter(
        storyId: storyId!,
        characterId: characterId,
        characterKey: characterKey,
        name: name,
        personality: personality,
        guidanceStyle: guidanceStyle,
        ttsVoice: ttsVoice,
        ttsStyle: ttsStyle,
        expressionKeys: expressionKeys,
      ),
    );
    if (ok) _characters = await _getCharacters(storyId!);
    safeNotify();
    return ok;
  }

  Future<bool> deleteCharacter(String characterId) async {
    if (storyId == null) return false;
    final ok = await runTask(
      () => _deleteCharacter(storyId: storyId!, characterId: characterId),
    );
    if (ok) _characters = await _getCharacters(storyId!);
    safeNotify();
    return ok;
  }

  /// 장면 목록과 이야기 요약을 함께 다시 읽습니다. 장면 수가 바뀌면 공개 가능 여부와
  /// 화면 상단 안내가 함께 달라집니다.
  Future<void> _refreshScenes() async {
    _scenes = await _getScenes(storyId!);
    _story = await _getStory(storyId!);
    safeNotify();
  }
}

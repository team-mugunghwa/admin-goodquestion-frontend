import '../../../core/error/exceptions.dart';
import '../../../core/error/failure.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/page_result.dart';
import '../domain/entities/story.dart';
import '../domain/repositories/story_repository.dart';

class StoryRepositoryImpl implements StoryRepository {
  const StoryRepositoryImpl(this._client);

  final DioClient _client;

  @override
  Future<PageResult<StorySummary>> getStories({
    StoryStatus? status,
    String? keyword,
    int page = 0,
    int size = 20,
  }) => _guard(
    () => _client.get(
      '/stories',
      queryParameters: {
        if (status != null) 'status': status.code,
        if (keyword != null && keyword.isNotEmpty) 'keyword': keyword,
        'page': page,
        'size': size,
      },
      parse: (data) => PageResult.fromJson(data, _toSummary),
    ),
  );

  @override
  Future<StoryDetail> getStory(String storyId) => _guard(
    () => _client.get(
      '/stories/$storyId',
      parse: (data) => _toDetail(_asMap(data)),
    ),
  );

  @override
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
  }) => _guard(
    () => _client.post(
      '/stories',
      body: _storyBody(
        title: title,
        summary: summary,
        childRole: childRole,
        intro: intro,
        imageUrl: imageUrl,
        difficulty: difficulty,
        estimatedMinutes: estimatedMinutes,
        status: status,
        topics: topics,
      ),
      parse: (data) => _toDetail(_asMap(data)),
    ),
  );

  @override
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
  }) => _guard(
    () => _client.patch(
      '/stories/$storyId',
      body: _storyBody(
        title: title,
        summary: summary,
        childRole: childRole,
        intro: intro,
        imageUrl: imageUrl,
        difficulty: difficulty,
        estimatedMinutes: estimatedMinutes,
        status: status,
        topics: topics,
      ),
      parse: (data) => _toDetail(_asMap(data)),
    ),
  );

  @override
  Future<void> deleteStory(String storyId) =>
      _guard(() => _client.delete('/stories/$storyId'));

  @override
  Future<List<StoryScene>> getScenes(String storyId) => _guard(
    () => _client.get('/stories/$storyId/scenes', parse: _toSceneList),
  );

  @override
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
  }) => _guard(
    () => _client.post(
      '/stories/$storyId/scenes',
      body: _sceneBody(
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
      ),
      parse: (data) => _toScene(_asMap(data)),
    ),
  );

  @override
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
  }) => _guard(
    () => _client.patch(
      '/stories/$storyId/scenes/$sceneId',
      body: _sceneBody(
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
      ),
      parse: (data) => _toScene(_asMap(data)),
    ),
  );

  @override
  Future<List<StoryScene>> reorderScenes({
    required String storyId,
    required List<String> sceneIds,
  }) => _guard(
    () => _client.put(
      '/stories/$storyId/scenes/order',
      body: {'sceneIds': sceneIds},
      parse: _toSceneList,
    ),
  );

  @override
  Future<void> deleteScene({
    required String storyId,
    required String sceneId,
  }) => _guard(() => _client.delete('/stories/$storyId/scenes/$sceneId'));

  @override
  Future<List<StoryCharacter>> getCharacters(String storyId) => _guard(
    () => _client.get(
      '/stories/$storyId/characters',
      parse: (data) => data is List
          ? data.whereType<Map<String, dynamic>>().map(_toCharacter).toList()
          : const <StoryCharacter>[],
    ),
  );

  @override
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
  }) {
    final body = {
      'characterKey': characterKey,
      'name': name,
      'personality': personality,
      if (guidanceStyle != null) 'guidanceStyle': guidanceStyle,
      if (ttsVoice != null) 'ttsVoice': ttsVoice,
      if (ttsStyle != null) 'ttsStyle': ttsStyle,
      if (expressionKeys != null) 'expressionKeys': expressionKeys,
    };
    // 생성과 수정의 요청 본문이 같아 한 메서드로 둡니다. 나누면 항목을 추가할 때
    // 한쪽만 고치는 실수가 납니다.
    return _guard(
      () => characterId == null
          ? _client.post(
              '/stories/$storyId/characters',
              body: body,
              parse: (data) => _toCharacter(_asMap(data)),
            )
          : _client.patch(
              '/stories/$storyId/characters/$characterId',
              body: body,
              parse: (data) => _toCharacter(_asMap(data)),
            ),
    );
  }

  @override
  Future<void> deleteCharacter({
    required String storyId,
    required String characterId,
  }) => _guard(
    () => _client.delete('/stories/$storyId/characters/$characterId'),
  );

  @override
  Future<List<Topic>> getTopics() => _guard(
    () => _client.get(
      '/topics',
      parse: (data) => data is List
          ? data
                .whereType<Map<String, dynamic>>()
                .map(
                  (json) => Topic(
                    id: json['id'] as String,
                    name: json['name'] as String? ?? '',
                    displayOrder: (json['displayOrder'] as num?)?.toInt() ?? 0,
                  ),
                )
                .toList()
          : const <Topic>[],
    ),
  );

  // ------------------------------------------------------------------ 변환

  static Map<String, dynamic> _storyBody({
    String? title,
    String? summary,
    String? childRole,
    String? intro,
    String? imageUrl,
    String? difficulty,
    int? estimatedMinutes,
    StoryStatus? status,
    List<String>? topics,
  }) => {
    if (title != null) 'title': title,
    if (summary != null) 'summary': summary,
    if (childRole != null) 'childRole': childRole,
    if (intro != null) 'intro': intro,
    if (imageUrl != null) 'imageUrl': imageUrl,
    if (difficulty != null) 'difficulty': difficulty,
    if (estimatedMinutes != null) 'estimatedMinutes': estimatedMinutes,
    if (status != null) 'status': status.code,
    // topics 는 빈 배열도 뜻이 있습니다("전부 지워라"). null 일 때만 뺍니다.
    if (topics != null) 'topics': topics,
  };

  static Map<String, dynamic> _sceneBody({
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
  }) => {
    if (sceneType != null) 'sceneType': sceneType.code,
    if (sceneDescription != null) 'sceneDescription': sceneDescription,
    if (imageUrl != null) 'imageUrl': imageUrl,
    if (characterId != null) 'characterId': characterId,
    if (characterName != null) 'characterName': characterName,
    if (characterOpening != null) 'characterOpening': characterOpening,
    if (characterClosing != null) 'characterClosing': characterClosing,
    if (sceneGoal != null) 'sceneGoal': sceneGoal,
    if (requiredElements != null) 'requiredElements': requiredElements,
    if (preferredTurns != null) 'preferredTurns': preferredTurns,
    if (maxTurns != null) 'maxTurns': maxTurns,
  };

  static StorySummary _toSummary(Map<String, dynamic> json) => StorySummary(
    id: json['id'] as String,
    title: json['title'] as String? ?? '',
    summary: json['summary'] as String? ?? '',
    difficulty: json['difficulty'] as String? ?? '',
    status: StoryStatus.fromCode(json['status'] as String?),
    topics: _stringList(json['topics']),
    sceneCount: (json['sceneCount'] as num?)?.toInt() ?? 0,
    estimatedMinutes: (json['estimatedMinutes'] as num?)?.toInt(),
    imageUrl: json['imageUrl'] as String?,
    updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '')?.toLocal(),
  );

  static StoryDetail _toDetail(Map<String, dynamic> json) => StoryDetail(
    id: json['id'] as String,
    title: json['title'] as String? ?? '',
    summary: json['summary'] as String? ?? '',
    childRole: json['childRole'] as String?,
    intro: json['intro'] as String?,
    imageUrl: json['imageUrl'] as String?,
    difficulty: json['difficulty'] as String? ?? 'EASY',
    estimatedMinutes: (json['estimatedMinutes'] as num?)?.toInt(),
    status: StoryStatus.fromCode(json['status'] as String?),
    topics: _stringList(json['topics']),
    sceneCount: (json['sceneCount'] as num?)?.toInt() ?? 0,
    sessionCount: (json['sessionCount'] as num?)?.toInt() ?? 0,
    updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '')?.toLocal(),
  );

  static List<StoryScene> _toSceneList(Object? data) => data is List
      ? data.whereType<Map<String, dynamic>>().map(_toScene).toList()
      : const [];

  static StoryScene _toScene(Map<String, dynamic> json) => StoryScene(
    id: json['id'] as String,
    sceneOrder: (json['sceneOrder'] as num?)?.toInt() ?? 0,
    sceneType: SceneType.fromCode(json['sceneType'] as String?),
    sceneDescription: json['sceneDescription'] as String? ?? '',
    characterId: json['characterId'] as String?,
    characterName: json['characterName'] as String?,
    characterOpening: json['characterOpening'] as String?,
    characterClosing: json['characterClosing'] as String?,
    sceneGoal: json['sceneGoal'] as String?,
    requiredElements: _stringList(json['requiredElements']),
    preferredTurns: (json['preferredTurns'] as num?)?.toInt(),
    maxTurns: (json['maxTurns'] as num?)?.toInt(),
    imageUrl: json['imageUrl'] as String?,
  );

  static StoryCharacter _toCharacter(Map<String, dynamic> json) =>
      StoryCharacter(
        id: json['id'] as String,
        characterKey: json['characterKey'] as String? ?? '',
        name: json['name'] as String? ?? '',
        personality: json['personality'] as String? ?? '',
        guidanceStyle: json['guidanceStyle'] as String?,
        ttsVoice: json['ttsVoice'] as String?,
        ttsStyle: json['ttsStyle'] as String?,
        expressionKeys: _stringList(json['expressionKeys']),
      );

  static List<String> _stringList(Object? value) =>
      value is List ? value.whereType<String>().toList() : const [];

  static Map<String, dynamic> _asMap(Object? data) {
    if (data is Map<String, dynamic>) return data;
    throw const ParseException();
  }

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on AppException catch (e) {
      throw Failure.fromException(e);
    }
  }
}

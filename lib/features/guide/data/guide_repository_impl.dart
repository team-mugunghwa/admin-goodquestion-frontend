import '../../../core/domain/content_status.dart';
import '../../../core/error/exceptions.dart';
import '../../../core/error/failure.dart';
import '../../../core/network/dio_client.dart';
import '../domain/entities/guide.dart';
import '../domain/repositories/guide_repository.dart';

class GuideRepositoryImpl implements GuideRepository {
  const GuideRepositoryImpl(this._client);

  final DioClient _client;

  @override
  Future<List<Guide>> getGuides({
    GuideCategory? category,
    ContentStatus? status,
  }) => _guard(
    () => _client.get(
      '/guides',
      queryParameters: {
        if (category != null) 'category': category.code,
        if (status != null) 'status': status.code,
      },
      parse: _toList,
    ),
  );

  @override
  Future<Guide> createGuide({
    required GuideCategory category,
    required String title,
    required String content,
    required ContentStatus status,
  }) => _guard(
    () => _client.post(
      '/guides',
      body: {
        'category': category.code,
        'title': title,
        'content': content,
        'status': status.code,
      },
      parse: (data) => _toGuide(_asMap(data)),
    ),
  );

  @override
  Future<Guide> updateGuide({
    required String guideId,
    GuideCategory? category,
    String? title,
    String? content,
    ContentStatus? status,
  }) => _guard(
    () => _client.patch(
      '/guides/$guideId',
      body: {
        if (category != null) 'category': category.code,
        if (title != null) 'title': title,
        if (content != null) 'content': content,
        if (status != null) 'status': status.code,
      },
      parse: (data) => _toGuide(_asMap(data)),
    ),
  );

  @override
  Future<List<Guide>> reorder({
    required GuideCategory category,
    required List<String> guideIds,
  }) => _guard(
    () => _client.put(
      '/guides/order',
      body: {'category': category.code, 'guideIds': guideIds},
      parse: _toList,
    ),
  );

  @override
  Future<void> deleteGuide(String guideId) =>
      _guard(() => _client.delete('/guides/$guideId'));

  static List<Guide> _toList(Object? data) => data is List
      ? data.whereType<Map<String, dynamic>>().map(_toGuide).toList()
      : const [];

  static Guide _toGuide(Map<String, dynamic> json) => Guide(
    id: json['id'] as String,
    category: GuideCategory.fromCode(json['category'] as String?),
    title: json['title'] as String? ?? '',
    content: json['content'] as String? ?? '',
    displayOrder: (json['displayOrder'] as num?)?.toInt() ?? 0,
    status: ContentStatus.fromCode(json['status'] as String?),
    updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '')?.toLocal(),
  );

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

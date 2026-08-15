import '../../../core/domain/content_status.dart';
import '../../../core/error/exceptions.dart';
import '../../../core/error/failure.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/page_result.dart';
import '../domain/entities/notice.dart';
import '../domain/repositories/notice_repository.dart';

/// 공지 CRUD.
///
/// DataSource 를 따로 두지 않았습니다. 엔드포인트가 다섯 개이고 전부 이 저장소만
/// 쓰는데, 한 겹을 더 두면 "어디에 있더라"를 매번 두 파일에서 찾게 됩니다.
/// DTO 도 마찬가지로 이 파일 안의 private 함수로 옮깁니다.
class NoticeRepositoryImpl implements NoticeRepository {
  const NoticeRepositoryImpl(this._client);

  final DioClient _client;

  @override
  Future<PageResult<NoticeSummary>> getNotices({
    ContentStatus? status,
    String? keyword,
    int page = 0,
    int size = 20,
  }) => _guard(
    () => _client.get(
      '/notices',
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
  Future<NoticeDetail> getNotice(String noticeId) => _guard(
    () => _client.get(
      '/notices/$noticeId',
      parse: (data) => _toDetail(_asMap(data)),
    ),
  );

  @override
  Future<NoticeDetail> createNotice({
    required String title,
    required String content,
    required NoticeCategory category,
    required bool pinned,
    required ContentStatus status,
  }) => _guard(
    () => _client.post(
      '/notices',
      body: {
        'title': title,
        'content': content,
        'category': category.code,
        'pinned': pinned,
        'status': status.code,
      },
      parse: (data) => _toDetail(_asMap(data)),
    ),
  );

  @override
  Future<NoticeDetail> updateNotice({
    required String noticeId,
    String? title,
    String? content,
    NoticeCategory? category,
    bool? pinned,
    ContentStatus? status,
  }) => _guard(
    () => _client.patch(
      '/notices/$noticeId',
      body: {
        if (title != null) 'title': title,
        if (content != null) 'content': content,
        if (category != null) 'category': category.code,
        if (pinned != null) 'pinned': pinned,
        if (status != null) 'status': status.code,
      },
      parse: (data) => _toDetail(_asMap(data)),
    ),
  );

  @override
  Future<void> deleteNotice(String noticeId) =>
      _guard(() => _client.delete('/notices/$noticeId'));

  static NoticeSummary _toSummary(Map<String, dynamic> json) => NoticeSummary(
    id: json['id'] as String,
    title: json['title'] as String? ?? '',
    category: NoticeCategory.fromCode(json['category'] as String?),
    pinned: json['pinned'] as bool? ?? false,
    status: ContentStatus.fromCode(json['status'] as String?),
    viewCount: (json['viewCount'] as num?)?.toInt() ?? 0,
    publishedAt: DateTime.tryParse(json['publishedAt'] as String? ?? '')?.toLocal(),
    authorName: json['authorName'] as String?,
    createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '')?.toLocal(),
  );

  static NoticeDetail _toDetail(Map<String, dynamic> json) => NoticeDetail(
    id: json['id'] as String,
    title: json['title'] as String? ?? '',
    content: json['content'] as String? ?? '',
    category: NoticeCategory.fromCode(json['category'] as String?),
    pinned: json['pinned'] as bool? ?? false,
    status: ContentStatus.fromCode(json['status'] as String?),
    viewCount: (json['viewCount'] as num?)?.toInt() ?? 0,
    publishedAt: DateTime.tryParse(json['publishedAt'] as String? ?? '')?.toLocal(),
    authorName: json['authorName'] as String?,
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

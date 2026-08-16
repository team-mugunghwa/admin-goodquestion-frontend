import '../../../core/error/exceptions.dart';
import '../../../core/error/failure.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/page_result.dart';
import '../domain/entities/inquiry.dart';
import '../domain/repositories/support_repository.dart';

class SupportRepositoryImpl implements SupportRepository {
  const SupportRepositoryImpl(this._client);

  final DioClient _client;

  @override
  Future<PageResult<InquirySummary>> getInquiries({
    InquiryStatus? status,
    InquiryCategory? category,
    String? keyword,
    int page = 0,
    int size = 20,
  }) => _guard(
    () => _client.get(
      '/inquiries',
      queryParameters: {
        if (status != null) 'status': status.code,
        if (category != null) 'category': category.code,
        if (keyword != null && keyword.isNotEmpty) 'keyword': keyword,
        'page': page,
        'size': size,
      },
      parse: (data) => PageResult.fromJson(data, _toSummary),
    ),
  );

  @override
  Future<InquiryDetail> getInquiry(String inquiryId) => _guard(
    () => _client.get(
      '/inquiries/$inquiryId',
      parse: (data) => _toDetail(_asMap(data)),
    ),
  );

  @override
  Future<InquiryAnswer> answer({
    required String inquiryId,
    required String content,
  }) => _guard(
    () => _client.post(
      '/inquiries/$inquiryId/answer',
      body: {'content': content},
      parse: (data) => _toAnswer(_asMap(data)),
    ),
  );

  @override
  Future<InquiryAnswer> updateAnswer({
    required String inquiryId,
    required String content,
  }) => _guard(
    () => _client.patch(
      '/inquiries/$inquiryId/answer',
      body: {'content': content},
      parse: (data) => _toAnswer(_asMap(data)),
    ),
  );

  @override
  Future<void> close(String inquiryId) => _guard(
    () => _client.post<void>('/inquiries/$inquiryId/close', parse: (_) {}),
  );

  @override
  Future<void> reopen(String inquiryId) => _guard(
    () => _client.post<void>('/inquiries/$inquiryId/reopen', parse: (_) {}),
  );

  @override
  Future<void> assignToMe(String inquiryId) => _guard(
    () => _client.put<void>('/inquiries/$inquiryId/assignee', parse: (_) {}),
  );

  @override
  Future<void> unassign(String inquiryId) =>
      _guard(() => _client.delete('/inquiries/$inquiryId/assignee'));

  @override
  Future<InquiryNote> addNote({
    required String inquiryId,
    required String body,
  }) => _guard(
    () => _client.post(
      '/inquiries/$inquiryId/notes',
      body: {'body': body},
      parse: (data) => _toNote(_asMap(data)),
    ),
  );

  @override
  Future<List<ReplyTemplate>> getTemplates() => _guard(
    () => _client.get(
      '/reply-templates',
      parse: (data) => data is List
          ? data.whereType<Map<String, dynamic>>().map(_toTemplate).toList()
          : const <ReplyTemplate>[],
    ),
  );

  @override
  Future<ReplyTemplate> saveTemplate({
    String? id,
    required String title,
    required String body,
  }) => _guard(() {
    final payload = {'title': title, 'body': body};
    return id == null
        ? _client.post(
            '/reply-templates',
            body: payload,
            parse: (data) => _toTemplate(_asMap(data)),
          )
        : _client.patch(
            '/reply-templates/$id',
            body: payload,
            parse: (data) => _toTemplate(_asMap(data)),
          );
  });

  @override
  Future<void> deleteTemplate(String id) =>
      _guard(() => _client.delete('/reply-templates/$id'));

  static InquirySummary _toSummary(Map<String, dynamic> json) => InquirySummary(
    id: json['id'] as String,
    parentId: json['parentId'] as String? ?? '',
    parentName: json['parentName'] as String? ?? '',
    parentEmail: json['parentEmail'] as String?,
    category: InquiryCategory.fromCode(json['category'] as String?),
    title: json['title'] as String? ?? '',
    status: InquiryStatus.fromCode(json['status'] as String?),
    answered: json['answered'] as bool? ?? false,
    answeredAt: DateTime.tryParse(json['answeredAt'] as String? ?? '')?.toLocal(),
    createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '')?.toLocal(),
    assigneeEmail: json['assigneeEmail'] as String?,
  );

  static InquiryDetail _toDetail(Map<String, dynamic> json) {
    final answer = json['answer'];
    return InquiryDetail(
      id: json['id'] as String,
      parentId: json['parentId'] as String? ?? '',
      parentName: json['parentName'] as String? ?? '',
      parentEmail: json['parentEmail'] as String?,
      category: InquiryCategory.fromCode(json['category'] as String?),
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
      status: InquiryStatus.fromCode(json['status'] as String?),
      answeredAt: DateTime.tryParse(
        json['answeredAt'] as String? ?? '',
      )?.toLocal(),
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '')?.toLocal(),
      answer: answer is Map<String, dynamic> ? _toAnswer(answer) : null,
      assigneeEmail: json['assigneeEmail'] as String?,
      notes: (json['notes'] as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(_toNote)
          .toList(),
    );
  }

  static InquiryNote _toNote(Map<String, dynamic> json) => InquiryNote(
    id: json['id'] as String? ?? '',
    authorEmail: json['authorEmail'] as String? ?? '',
    body: json['body'] as String? ?? '',
    createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '')?.toLocal(),
  );

  static ReplyTemplate _toTemplate(Map<String, dynamic> json) => ReplyTemplate(
    id: json['id'] as String? ?? '',
    title: json['title'] as String? ?? '',
    body: json['body'] as String? ?? '',
    updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '')?.toLocal(),
  );

  static InquiryAnswer _toAnswer(Map<String, dynamic> json) => InquiryAnswer(
    id: json['id'] as String? ?? '',
    adminName: json['adminName'] as String? ?? '',
    content: json['content'] as String? ?? '',
    createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '')?.toLocal(),
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

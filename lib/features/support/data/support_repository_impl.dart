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
    );
  }

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

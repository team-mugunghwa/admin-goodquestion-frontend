import '../../../core/error/exceptions.dart';
import '../../../core/error/failure.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/page_result.dart';
import '../domain/entities/member.dart';
import '../domain/repositories/member_repository.dart';

class MemberRepositoryImpl implements MemberRepository {
  const MemberRepositoryImpl(this._client);

  final DioClient _client;

  @override
  Future<PageResult<MemberSummary>> getMembers({
    MemberStatus? status,
    String? keyword,
    int page = 0,
    int size = 20,
  }) => _guard(
    () => _client.get(
      '/members',
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
  Future<MemberDetail> getMember(String parentId) => _guard(
    () => _client.get(
      '/members/$parentId',
      parse: (data) => _toDetail(_asMap(data)),
    ),
  );

  @override
  Future<PageResult<StorySessionSummary>> getStorySessions({
    required String parentId,
    int page = 0,
    int size = 20,
  }) => _guard(
    () => _client.get(
      '/members/$parentId/sessions',
      queryParameters: {'page': page, 'size': size},
      parse: (data) => PageResult.fromJson(data, _toStorySession),
    ),
  );

  @override
  Future<MemberDetail> suspend({
    required String parentId,
    required String reason,
  }) => _guard(
    () => _client.post(
      '/members/$parentId/suspend',
      body: {'reason': reason},
      parse: (data) => _toDetail(_asMap(data)),
    ),
  );

  @override
  Future<MemberDetail> restore(String parentId) => _guard(
    () => _client.post(
      '/members/$parentId/restore',
      parse: (data) => _toDetail(_asMap(data)),
    ),
  );

  @override
  Future<void> revokeLoginSessions(String parentId) => _guard(
    () => _client.post<void>(
      '/members/$parentId/login-sessions/revoke',
      parse: (_) {},
    ),
  );

  static MemberSummary _toSummary(Map<String, dynamic> json) => MemberSummary(
    id: json['id'] as String,
    name: json['name'] as String? ?? '',
    email: json['email'] as String?,
    provider: json['provider'] as String? ?? 'LOCAL',
    status: MemberStatus.fromCode(json['status'] as String?),
    locked: json['locked'] as bool? ?? false,
    childCount: (json['childCount'] as num?)?.toInt() ?? 0,
    createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '')?.toLocal(),
  );

  static MemberDetail _toDetail(Map<String, dynamic> json) => MemberDetail(
    id: json['id'] as String,
    name: json['name'] as String? ?? '',
    email: json['email'] as String?,
    provider: json['provider'] as String? ?? 'LOCAL',
    status: MemberStatus.fromCode(json['status'] as String?),
    locked: json['locked'] as bool? ?? false,
    lockedUntil: DateTime.tryParse(json['lockedUntil'] as String? ?? '')?.toLocal(),
    suspendedReason: json['suspendedReason'] as String?,
    suspendedAt: DateTime.tryParse(json['suspendedAt'] as String? ?? '')?.toLocal(),
    lastLoginIp: json['lastLoginIp'] as String?,
    createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '')?.toLocal(),
    children: (json['children'] as List? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(
          (child) => ChildProfile(
            id: child['id'] as String,
            name: child['name'] as String? ?? '',
            birthYear: (child['birthYear'] as num?)?.toInt() ?? 0,
            createdAt: DateTime.tryParse(
              child['createdAt'] as String? ?? '',
            )?.toLocal(),
          ),
        )
        .toList(),
    loginSessions: (json['loginSessions'] as List? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(
          (session) => LoginSession(
            id: session['id'] as String,
            active: session['active'] as bool? ?? false,
            createdAt: DateTime.tryParse(
              session['createdAt'] as String? ?? '',
            )?.toLocal(),
            expiresAt: DateTime.tryParse(
              session['expiresAt'] as String? ?? '',
            )?.toLocal(),
            revokedAt: DateTime.tryParse(
              session['revokedAt'] as String? ?? '',
            )?.toLocal(),
          ),
        )
        .toList(),
    inquiryCount: (json['inquiryCount'] as num?)?.toInt() ?? 0,
  );

  static StorySessionSummary _toStorySession(Map<String, dynamic> json) =>
      StorySessionSummary(
        id: json['id'] as String,
        childName: json['childName'] as String? ?? '',
        storyTitle: json['storyTitle'] as String? ?? '',
        status: json['status'] as String? ?? '',
        safetyFlagged: json['safetyFlagged'] as bool? ?? false,
        startedAt: DateTime.tryParse(json['startedAt'] as String? ?? '')?.toLocal(),
        completedAt: DateTime.tryParse(
          json['completedAt'] as String? ?? '',
        )?.toLocal(),
        lastActivityAt: DateTime.tryParse(
          json['lastActivityAt'] as String? ?? '',
        )?.toLocal(),
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

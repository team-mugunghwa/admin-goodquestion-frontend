import 'dart:async';

import 'package:get_it/get_it.dart';

import '../../features/audit/data/audit_log_repository_impl.dart';
import '../../features/audit/domain/audit_log.dart';
import '../../features/auth/data/datasources/admin_token_store.dart';
import '../../features/auth/data/datasources/auth_remote_data_source.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/auth_use_cases.dart';
import '../../features/auth/presentation/viewmodels/admin_session.dart';
import '../../features/dashboard/data/dashboard_repository_impl.dart';
import '../../features/dashboard/domain/repositories/dashboard_repository.dart';
import '../../features/dashboard/domain/usecases/get_dashboard_summary_use_case.dart';
import '../../features/database/data/database_repository_impl.dart';
import '../../features/database/domain/repositories/database_repository.dart';
import '../../features/database/domain/usecases/database_use_cases.dart';
import '../../features/guide/data/guide_repository_impl.dart';
import '../../features/guide/domain/repositories/guide_repository.dart';
import '../../features/guide/domain/usecases/guide_use_cases.dart';
import '../../features/member/data/member_repository_impl.dart';
import '../../features/member/domain/repositories/member_repository.dart';
import '../../features/member/domain/usecases/member_use_cases.dart';
import '../../features/notice/data/notice_repository_impl.dart';
import '../../features/notice/domain/repositories/notice_repository.dart';
import '../../features/notice/domain/usecases/notice_use_cases.dart';
import '../../features/settings/data/tts_vendor_repository_impl.dart';
import '../../features/settings/domain/repositories/tts_vendor_repository.dart';
import '../../features/settings/domain/usecases/tts_vendor_use_cases.dart';
import '../../features/story/data/story_repository_impl.dart';
import '../../features/story/domain/repositories/story_repository.dart';
import '../../features/story/domain/usecases/story_use_cases.dart';
import '../../features/support/data/support_repository_impl.dart';
import '../../features/support/domain/repositories/support_repository.dart';
import '../../features/support/domain/usecases/support_use_cases.dart';
import '../network/dio_client.dart';

/// 앱 전역 서비스 로케이터.
///
/// ## 여기에 등록하는 것 / 안 하는 것
/// - Repository, UseCase, DataSource, DioClient - 위젯 트리와 무관한 객체
/// - ViewModel 은 등록하지 않습니다. 화면 생명주기를 따라야 하므로
///   `ChangeNotifierProvider` 로 만듭니다. 단 하나의 예외가 [AdminSession] 인데,
///   앱 전체가 공유하는 로그인 상태라 `app.dart` 의 MultiProvider 에 올립니다.
///
/// **여러 명이 동시에 건드리기 쉬운 파일입니다.** 수정 전에 팀에 알리세요.
final GetIt getIt = GetIt.instance;

Future<void> configureDependencies() async {
  // ---- core ----
  getIt
    ..registerLazySingleton<AdminTokenStore>(AdminTokenStore.new)
    ..registerLazySingleton<DioClient>(
      () => DioClient(
        tokenProvider: getIt<AdminTokenStore>().read,
        tokenRefresher: _refreshTokens,
        onUnauthorized: _handleUnauthorized,
      ),
    );

  _registerAuth();
  _registerDashboard();
  _registerContent();
  _registerOperations();
  _registerSettings();
}

void _registerAuth() {
  getIt
    ..registerLazySingleton<AuthRemoteDataSource>(
      () => AuthRemoteDataSource(getIt<DioClient>()),
    )
    ..registerLazySingleton<AuthRepository>(
      () => AuthRepositoryImpl(
        getIt<AuthRemoteDataSource>(),
        getIt<AdminTokenStore>(),
      ),
    )
    ..registerLazySingleton(() => LoginUseCase(getIt<AuthRepository>()))
    ..registerLazySingleton(() => LogoutUseCase(getIt<AuthRepository>()))
    ..registerLazySingleton(
      () => RestoreSessionUseCase(getIt<AuthRepository>()),
    )
    ..registerLazySingleton(
      () => ChangePasswordUseCase(getIt<AuthRepository>()),
    )
    ..registerLazySingleton(() => GetAdminsUseCase(getIt<AuthRepository>()))
    ..registerLazySingleton(() => CreateAdminUseCase(getIt<AuthRepository>()))
    ..registerLazySingleton(() => UpdateAdminUseCase(getIt<AuthRepository>()))
    ..registerLazySingleton(() => DeleteAdminUseCase(getIt<AuthRepository>()))
    // 전역 세션. 라우터가 이 인스턴스를 구독하므로 앱에 하나만 있어야 합니다.
    ..registerLazySingleton<AdminSession>(
      () => AdminSession(
        login: getIt<LoginUseCase>(),
        logout: getIt<LogoutUseCase>(),
        restoreSession: getIt<RestoreSessionUseCase>(),
      ),
    );
}

void _registerDashboard() {
  getIt
    ..registerLazySingleton<DashboardRepository>(
      () => DashboardRepositoryImpl(getIt<DioClient>()),
    )
    ..registerLazySingleton(
      () => GetDashboardSummaryUseCase(getIt<DashboardRepository>()),
    );
}

/// 공지 / 이용안내 / 이야기 - 사용자 앱에 그대로 나가는 콘텐츠.
void _registerContent() {
  getIt
    ..registerLazySingleton<NoticeRepository>(
      () => NoticeRepositoryImpl(getIt<DioClient>()),
    )
    ..registerLazySingleton(() => GetNoticesUseCase(getIt<NoticeRepository>()))
    ..registerLazySingleton(() => GetNoticeUseCase(getIt<NoticeRepository>()))
    ..registerLazySingleton(
      () => CreateNoticeUseCase(getIt<NoticeRepository>()),
    )
    ..registerLazySingleton(
      () => UpdateNoticeUseCase(getIt<NoticeRepository>()),
    )
    ..registerLazySingleton(
      () => DeleteNoticeUseCase(getIt<NoticeRepository>()),
    )
    ..registerLazySingleton(
      () => GetNoticeRevisionsUseCase(getIt<NoticeRepository>()),
    )
    ..registerLazySingleton(
      () => RevertNoticeUseCase(getIt<NoticeRepository>()),
    )
    ..registerLazySingleton(
      () => ScheduleNoticeUseCase(getIt<NoticeRepository>()),
    )
    ..registerLazySingleton(
      () => CancelNoticeScheduleUseCase(getIt<NoticeRepository>()),
    )
    ..registerLazySingleton<GuideRepository>(
      () => GuideRepositoryImpl(getIt<DioClient>()),
    )
    ..registerLazySingleton(() => GetGuidesUseCase(getIt<GuideRepository>()))
    ..registerLazySingleton(() => CreateGuideUseCase(getIt<GuideRepository>()))
    ..registerLazySingleton(() => UpdateGuideUseCase(getIt<GuideRepository>()))
    ..registerLazySingleton(
      () => ReorderGuidesUseCase(getIt<GuideRepository>()),
    )
    ..registerLazySingleton(() => DeleteGuideUseCase(getIt<GuideRepository>()))
    ..registerLazySingleton<StoryRepository>(
      () => StoryRepositoryImpl(getIt<DioClient>()),
    )
    ..registerLazySingleton(() => GetStoriesUseCase(getIt<StoryRepository>()))
    ..registerLazySingleton(() => GetStoryUseCase(getIt<StoryRepository>()))
    ..registerLazySingleton(() => SaveStoryUseCase(getIt<StoryRepository>()))
    ..registerLazySingleton(() => DeleteStoryUseCase(getIt<StoryRepository>()))
    ..registerLazySingleton(() => GetScenesUseCase(getIt<StoryRepository>()))
    ..registerLazySingleton(() => SaveSceneUseCase(getIt<StoryRepository>()))
    ..registerLazySingleton(
      () => ReorderScenesUseCase(getIt<StoryRepository>()),
    )
    ..registerLazySingleton(() => DeleteSceneUseCase(getIt<StoryRepository>()))
    ..registerLazySingleton(
      () => GetCharactersUseCase(getIt<StoryRepository>()),
    )
    ..registerLazySingleton(
      () => SaveCharacterUseCase(getIt<StoryRepository>()),
    )
    ..registerLazySingleton(
      () => DeleteCharacterUseCase(getIt<StoryRepository>()),
    )
    ..registerLazySingleton(() => GetTopicsUseCase(getIt<StoryRepository>()));
}

/// 사용자 관리 / 고객센터 / 감사 로그 - 운영 업무.
void _registerOperations() {
  getIt
    ..registerLazySingleton<MemberRepository>(
      () => MemberRepositoryImpl(getIt<DioClient>()),
    )
    ..registerLazySingleton(() => GetMembersUseCase(getIt<MemberRepository>()))
    ..registerLazySingleton(() => GetMemberUseCase(getIt<MemberRepository>()))
    ..registerLazySingleton(
      () => GetStorySessionsUseCase(getIt<MemberRepository>()),
    )
    ..registerLazySingleton(
      () => SuspendMemberUseCase(getIt<MemberRepository>()),
    )
    ..registerLazySingleton(
      () => RestoreMemberUseCase(getIt<MemberRepository>()),
    )
    ..registerLazySingleton(
      () => RevokeLoginSessionsUseCase(getIt<MemberRepository>()),
    )
    ..registerLazySingleton<SupportRepository>(
      () => SupportRepositoryImpl(getIt<DioClient>()),
    )
    ..registerLazySingleton(
      () => GetInquiriesUseCase(getIt<SupportRepository>()),
    )
    ..registerLazySingleton(() => GetInquiryUseCase(getIt<SupportRepository>()))
    ..registerLazySingleton(
      () => AnswerInquiryUseCase(getIt<SupportRepository>()),
    )
    ..registerLazySingleton(
      () => UpdateAnswerUseCase(getIt<SupportRepository>()),
    )
    ..registerLazySingleton(
      () => CloseInquiryUseCase(getIt<SupportRepository>()),
    )
    ..registerLazySingleton(
      () => ReopenInquiryUseCase(getIt<SupportRepository>()),
    )
    ..registerLazySingleton(
      () => AssignInquiryUseCase(getIt<SupportRepository>()),
    )
    ..registerLazySingleton(
      () => UnassignInquiryUseCase(getIt<SupportRepository>()),
    )
    ..registerLazySingleton(
      () => AddInquiryNoteUseCase(getIt<SupportRepository>()),
    )
    ..registerLazySingleton(
      () => GetReplyTemplatesUseCase(getIt<SupportRepository>()),
    )
    ..registerLazySingleton(
      () => SaveReplyTemplateUseCase(getIt<SupportRepository>()),
    )
    ..registerLazySingleton(
      () => DeleteReplyTemplateUseCase(getIt<SupportRepository>()),
    )
    ..registerLazySingleton<AuditLogRepository>(
      () => AuditLogRepositoryImpl(getIt<DioClient>()),
    )
    ..registerLazySingleton<DatabaseRepository>(
      () => DatabaseRepositoryImpl(getIt<DioClient>()),
    )
    ..registerLazySingleton(() => GetTablesUseCase(getIt<DatabaseRepository>()))
    ..registerLazySingleton(
      () => GetRelationsUseCase(getIt<DatabaseRepository>()),
    )
    ..registerLazySingleton(() => GetTableUseCase(getIt<DatabaseRepository>()))
    ..registerLazySingleton(
      () => GetTableRowsUseCase(getIt<DatabaseRepository>()),
    );
}

/// 서비스 동작 설정 - 콘텐츠도 사용자 관리도 아닌, 서버가 무엇으로 도는지를 정하는 값.
///
/// 운영 업무와 묶지 않고 따로 둡니다. 앞으로 설정 항목이 늘어날 자리라
/// [_registerOperations] 안에 섞이면 무엇이 설정이고 무엇이 업무인지 흐려집니다.
void _registerSettings() {
  getIt
    ..registerLazySingleton<TtsVendorRepository>(
      () => TtsVendorRepositoryImpl(getIt<DioClient>()),
    )
    ..registerLazySingleton(
      () => GetTtsVendorUseCase(getIt<TtsVendorRepository>()),
    )
    ..registerLazySingleton(
      () => UpdateTtsVendorUseCase(getIt<TtsVendorRepository>()),
    );
}

/// 진행 중인 재발급. 동시에 여러 요청이 401 을 받아도 실제 호출은 한 번만 나갑니다.
///
/// 리프레시 토큰은 1회용으로 회전하므로, 두 번 부르면 두 번째가 "이미 쓴 토큰"으로
/// 거절되고 정상 사용자가 로그아웃됩니다.
Future<bool>? _refreshInFlight;

Future<bool> _refreshTokens() {
  return _refreshInFlight ??= _doRefresh().whenComplete(() {
    _refreshInFlight = null;
  });
}

Future<bool> _doRefresh() async {
  final store = getIt<AdminTokenStore>();
  final refreshToken = await store.readRefreshToken();
  if (refreshToken == null || refreshToken.isEmpty) return false;

  try {
    final token = await getIt<AuthRemoteDataSource>().refresh(refreshToken);
    await store.save(
      accessToken: token.accessToken,
      refreshToken: token.refreshToken,
    );
    return true;
  } catch (_) {
    // 리프레시 토큰까지 무효입니다. 남은 토큰을 지워 다음 요청이 헛되이
    // 재발급을 시도하지 않게 합니다.
    await store.clear();
    return false;
  }
}

/// 재발급까지 실패했을 때. 세션을 비우면 라우터가 로그인 화면으로 보냅니다.
void _handleUnauthorized() {
  unawaited(getIt<AdminTokenStore>().clear());
  getIt<AdminSession>().onSessionExpired();
}

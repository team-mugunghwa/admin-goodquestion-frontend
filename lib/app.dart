import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'core/di/injector.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/viewmodels/admin_session.dart';

/// 앱의 루트 위젯.
///
/// `MultiProvider` 에는 **앱 전체 수명 동안 살아 있어야 하는 상태만** 올립니다.
/// 지금은 [AdminSession] 하나뿐입니다. 화면 단위 ViewModel 은 각 화면에서
/// `ChangeNotifierProvider` 로 만드세요.
class GoodQuestionAdminApp extends StatefulWidget {
  const GoodQuestionAdminApp({super.key});

  @override
  State<GoodQuestionAdminApp> createState() => _GoodQuestionAdminAppState();
}

class _GoodQuestionAdminAppState extends State<GoodQuestionAdminApp> {
  late final AdminSession _session = getIt<AdminSession>();

  /// 라우터를 State 에 들고 있습니다. build 마다 새로 만들면 화면 전환 때마다
  /// 라우팅 상태가 초기화되어 뒤로 가기가 동작하지 않습니다.
  late final GoRouter _router = createRouter(_session);

  @override
  void initState() {
    super.initState();
    // 저장된 토큰으로 세션을 되살립니다. 끝날 때까지 라우터는 판단을 미룹니다.
    _session.restore();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AdminSession>.value(
      value: _session,
      child: MaterialApp.router(
        title: '굿퀘스천 관리자',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        // 다크 모드는 만들지 않습니다. 표와 상태 배지가 화면의 대부분이라
        // 두 벌을 검수할 여력이 없고, 운영자가 낮에 보는 화면입니다.
        themeMode: ThemeMode.light,
        routerConfig: _router,
      ),
    );
  }
}

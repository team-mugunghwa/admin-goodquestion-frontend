import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'app.dart';
import 'core/di/injector.dart';

Future<void> main() async {
  // DI 등록 등 비동기 초기화를 하기 전에 반드시 호출해야 합니다.
  WidgetsFlutterBinding.ensureInitialized();

  // 주소에서 # 을 뺍니다. 관리자 콘솔은 문의 상세 링크를 서로 주고받는 일이
  // 잦은데, /#/inquiries/... 형태는 붙여 넣을 때 잘리는 경우가 있습니다.
  usePathUrlStrategy();

  await configureDependencies();

  runApp(const GoodQuestionAdminApp());
}

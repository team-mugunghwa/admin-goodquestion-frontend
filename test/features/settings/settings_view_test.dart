import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goodquestion_admin/core/di/injector.dart';
import 'package:goodquestion_admin/core/error/failure.dart';
import 'package:goodquestion_admin/core/theme/app_theme.dart';
import 'package:goodquestion_admin/features/settings/domain/entities/tts_vendor.dart';
import 'package:goodquestion_admin/features/settings/domain/repositories/tts_vendor_repository.dart';
import 'package:goodquestion_admin/features/settings/domain/usecases/tts_vendor_use_cases.dart';
import 'package:goodquestion_admin/features/settings/presentation/views/settings_view.dart';
import 'package:mocktail/mocktail.dart';

class _MockTtsVendorRepository extends Mock implements TtsVendorRepository {}

final DateTime _before = DateTime(2026, 8, 16, 15, 37);
final DateTime _after = DateTime(2026, 8, 18, 9, 2);

void main() {
  setUpAll(() => registerFallbackValue(TtsVendor.openai));

  late _MockTtsVendorRepository repository;

  setUp(() {
    repository = _MockTtsVendorRepository();
    // 화면이 getIt 에서 UseCase 를 직접 꺼내므로 같은 타입으로 등록해 둡니다.
    getIt
      ..registerLazySingleton(() => GetTtsVendorUseCase(repository))
      ..registerLazySingleton(() => UpdateTtsVendorUseCase(repository));
  });

  tearDown(getIt.reset);

  void stubGet(TtsVendor vendor) {
    when(repository.getTtsVendor).thenAnswer(
      (_) async => TtsVendorSetting(vendor: vendor, updatedAt: _before),
    );
  }

  /// 지금 화면에 골라져 있는 벤더. 눈에 보이는 컨트롤의 상태를 그대로 읽습니다.
  Set<TtsVendor> selectedOf(WidgetTester tester) => tester
      .widget<SegmentedButton<TtsVendor>>(
        find.byType(SegmentedButton<TtsVendor>),
      )
      .selected;

  /// 컨트롤이 잠겨 있는지. 콜백이 비어 있으면 세그먼트가 눌리지 않습니다.
  bool lockedOf(WidgetTester tester) =>
      tester
          .widget<SegmentedButton<TtsVendor>>(
            find.byType(SegmentedButton<TtsVendor>),
          )
          .onSelectionChanged ==
      null;

  Future<void> pumpSettings(WidgetTester tester) async {
    // 스낵바까지 한 화면에 들어가도록 넉넉하게 잡습니다.
    tester.view.physicalSize = const Size(1400, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    // 실제 앱에서는 AdminShell 이 Scaffold 를 씌웁니다. 스낵바가 뜨려면
    // 조상에 Scaffold 가 있어야 해서 여기서도 같은 모양으로 감쌉니다.
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(body: SettingsView()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('화면을 열면 서버가 걸어 둔 벤더가 골라져 있다', (tester) async {
    stubGet(TtsVendor.gemini);

    await pumpSettings(tester);

    expect(selectedOf(tester), {TtsVendor.gemini});
    // 대조군. 화면이 기본값을 그려 두고 통과하는 것이 아니다.
    expect(selectedOf(tester), isNot(contains(TtsVendor.openai)));
    expect(find.textContaining('마지막 변경 2026-08-16 15:37'), findsOneWidget);
  });

  testWidgets('서버 값이 다르면 골라지는 것도 달라진다', (tester) async {
    // 위 테스트의 대조군. 'gemini' 가 화면에 박혀 있는 것이 아님을 확인한다.
    stubGet(TtsVendor.chirp3);

    await pumpSettings(tester);

    expect(selectedOf(tester), {TtsVendor.chirp3});
  });

  testWidgets('다른 엔진을 고르면 그 값으로 저장 요청이 나간다', (tester) async {
    stubGet(TtsVendor.openai);
    when(() => repository.updateTtsVendor(TtsVendor.gemini)).thenAnswer(
      (_) async =>
          TtsVendorSetting(vendor: TtsVendor.gemini, updatedAt: _after),
    );

    await pumpSettings(tester);
    await tester.tap(find.text('Gemini'));
    await tester.pumpAndSettle();

    verify(() => repository.updateTtsVendor(TtsVendor.gemini)).called(1);
    // 대조군. 누른 것과 다른 값이 나가지 않는다.
    verifyNever(() => repository.updateTtsVendor(TtsVendor.chirp3));
    expect(selectedOf(tester), {TtsVendor.gemini});
    // 성공하면 서버가 준 시각으로 갱신된다.
    expect(find.textContaining('마지막 변경 2026-08-18 09:02'), findsOneWidget);
    expect(find.text('바꿨습니다. 지금 합성 엔진은 Gemini 입니다.'), findsOneWidget);
  });

  testWidgets('저장에 실패하면 고르기 전 값으로 되돌아간다', (tester) async {
    stubGet(TtsVendor.openai);
    final gate = Completer<TtsVendorSetting>();
    when(
      () => repository.updateTtsVendor(TtsVendor.gemini),
    ).thenAnswer((_) => gate.future);

    await pumpSettings(tester);
    await tester.tap(find.text('Gemini'));
    await tester.pump();

    // 대조군. 되돌아간 것을 확인하려면 먼저 실제로 옮겨 갔어야 한다. 이 줄이 없으면
    // "아예 안 움직였다"와 "옮겼다가 되돌렸다"를 구분하지 못한다.
    expect(selectedOf(tester), {TtsVendor.gemini});

    gate.completeError(
      const ServerFailure(message: '설정을 바꾸지 못했습니다.', code: 'INTERNAL_ERROR'),
    );
    await tester.pumpAndSettle();

    expect(selectedOf(tester), {TtsVendor.openai});
    expect(find.textContaining('마지막 변경 2026-08-16 15:37'), findsOneWidget);
    // 무엇이 실패했는지와 되돌렸다는 사실이 함께 보여야 한다.
    expect(find.text('설정을 바꾸지 못했습니다. 이전 값으로 되돌렸습니다.'), findsOneWidget);
  });

  testWidgets('저장 중에는 다시 고를 수 없다', (tester) async {
    stubGet(TtsVendor.openai);
    final gate = Completer<TtsVendorSetting>();
    when(
      () => repository.updateTtsVendor(TtsVendor.gemini),
    ).thenAnswer((_) => gate.future);
    when(() => repository.updateTtsVendor(TtsVendor.chirp3)).thenAnswer(
      (_) async =>
          TtsVendorSetting(vendor: TtsVendor.chirp3, updatedAt: _after),
    );

    await pumpSettings(tester);
    // 대조군. 저장이 돌기 전에는 잠겨 있지 않다.
    expect(lockedOf(tester), isFalse);

    await tester.tap(find.text('Gemini'));
    await tester.pump();
    expect(lockedOf(tester), isTrue);

    await tester.tap(find.text('Chirp 3'));
    await tester.pump();
    verifyNever(() => repository.updateTtsVendor(TtsVendor.chirp3));

    gate.complete(
      TtsVendorSetting(vendor: TtsVendor.gemini, updatedAt: _after),
    );
    await tester.pumpAndSettle();

    // 대조군. 잠금이 저장이 도는 동안만이어야 한다. 영영 잠기면 화면이 죽은 것이다.
    expect(lockedOf(tester), isFalse);
    await tester.tap(find.text('Chirp 3'));
    await tester.pumpAndSettle();
    verify(() => repository.updateTtsVendor(TtsVendor.chirp3)).called(1);
  });

  testWidgets('키가 없으면 합성이 멈춘다는 경고와 환경변수 이름을 늘 보여 준다', (tester) async {
    stubGet(TtsVendor.openai);

    await pumpSettings(tester);

    expect(find.text('키가 없는 엔진으로 바꾸면 음성 합성이 통째로 503 으로 멈춥니다'), findsOneWidget);
    // 키를 어디서 고쳐야 하는지까지 적어야 되돌리는 것 말고도 할 수 있는 일이 생긴다.
    for (final vendor in TtsVendor.values) {
      expect(find.textContaining(vendor.envKey), findsWidgets);
    }
    // 이 화면이 키 유무를 모른다는 사실을 숨기지 않는다.
    expect(find.textContaining('키가 들어 있는지 확인하지 못합니다'), findsOneWidget);
  });
}

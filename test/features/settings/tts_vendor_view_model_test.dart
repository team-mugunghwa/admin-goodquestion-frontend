import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:goodquestion_admin/core/error/failure.dart';
import 'package:goodquestion_admin/core/state/view_state.dart';
import 'package:goodquestion_admin/features/settings/domain/entities/tts_vendor.dart';
import 'package:goodquestion_admin/features/settings/domain/repositories/tts_vendor_repository.dart';
import 'package:goodquestion_admin/features/settings/domain/usecases/tts_vendor_use_cases.dart';
import 'package:goodquestion_admin/features/settings/presentation/viewmodels/tts_vendor_view_model.dart';
import 'package:mocktail/mocktail.dart';

class _MockTtsVendorRepository extends Mock implements TtsVendorRepository {}

/// 서버가 준 값. 로컬 시각으로 만들어 표기가 실행 환경의 시간대에 흔들리지 않게 합니다.
final DateTime _before = DateTime(2026, 8, 16, 15, 37);
final DateTime _after = DateTime(2026, 8, 18, 9, 2);

void main() {
  /// mocktail 의 any() 가 쓸 기본값.
  setUpAll(() => registerFallbackValue(TtsVendor.openai));

  late _MockTtsVendorRepository repository;
  late TtsVendorViewModel viewModel;

  setUp(() {
    repository = _MockTtsVendorRepository();
    viewModel = TtsVendorViewModel(
      getTtsVendor: GetTtsVendorUseCase(repository),
      updateTtsVendor: UpdateTtsVendorUseCase(repository),
    );
  });

  void stubGet(TtsVendor vendor) {
    when(repository.getTtsVendor).thenAnswer(
      (_) async => TtsVendorSetting(vendor: vendor, updatedAt: _before),
    );
  }

  test('불러오면 서버가 준 벤더와 시각을 그대로 들고 있다', () async {
    stubGet(TtsVendor.gemini);

    await viewModel.load();

    expect(viewModel.setting?.vendor, TtsVendor.gemini);
    expect(viewModel.setting?.updatedAt, _before);
    // 대조군. 기본값을 들고 있다가 통과하는 것이 아니라 서버 값을 받은 것이다.
    expect(viewModel.setting?.vendor, isNot(TtsVendor.openai));
    expect(viewModel.state, ViewState.success);
  });

  test('벤더를 바꾸면 고른 값으로 저장하고 응답으로 시각을 갱신한다', () async {
    stubGet(TtsVendor.openai);
    when(() => repository.updateTtsVendor(TtsVendor.chirp3)).thenAnswer(
      (_) async =>
          TtsVendorSetting(vendor: TtsVendor.chirp3, updatedAt: _after),
    );

    await viewModel.load();
    final ok = await viewModel.change(TtsVendor.chirp3);

    expect(ok, isTrue);
    verify(() => repository.updateTtsVendor(TtsVendor.chirp3)).called(1);
    // 대조군. 아무 값이나 나가는 것이 아니라 고른 값만 나간다.
    verifyNever(() => repository.updateTtsVendor(TtsVendor.gemini));
    expect(viewModel.setting?.vendor, TtsVendor.chirp3);
    // 시각은 서버 응답에서 온다. 화면이 직접 "지금"을 찍으면 서버 기록과 어긋난다.
    expect(viewModel.setting?.updatedAt, _after);
  });

  test('저장에 실패하면 고르기 전 벤더로 돌아가고 이유가 남는다', () async {
    stubGet(TtsVendor.openai);
    when(() => repository.updateTtsVendor(TtsVendor.gemini)).thenThrow(
      const ServerFailure(message: '설정을 바꾸지 못했습니다.', code: 'INTERNAL_ERROR'),
    );

    await viewModel.load();
    final ok = await viewModel.change(TtsVendor.gemini);

    expect(ok, isFalse);
    expect(viewModel.setting?.vendor, TtsVendor.openai);
    // 되돌리면서 시각까지 잃어버리면 언제 마지막으로 바뀌었는지 알 수 없게 된다.
    expect(viewModel.setting?.updatedAt, _before);
    expect(viewModel.errorMessage, '설정을 바꾸지 못했습니다.');
    // 조작 실패는 화면을 스피너나 오류 화면으로 덮지 않는다. 되돌린 값을 봐야 한다.
    expect(viewModel.state, ViewState.success);
  });

  test('저장이 도는 동안 isBusy 가 올라갔다가 끝나면 내려간다', () async {
    stubGet(TtsVendor.openai);
    final gate = Completer<TtsVendorSetting>();
    when(
      () => repository.updateTtsVendor(TtsVendor.gemini),
    ).thenAnswer((_) => gate.future);

    await viewModel.load();
    // 대조군. 저장 전에는 잠기지 않은 상태다.
    expect(viewModel.isBusy, isFalse);

    final pending = viewModel.change(TtsVendor.gemini);
    await Future<void>.delayed(Duration.zero);
    expect(viewModel.isBusy, isTrue);
    // 누른 즉시 컨트롤이 움직여야 저장 버튼이 없다는 것이 납득된다.
    expect(viewModel.setting?.vendor, TtsVendor.gemini);

    gate.complete(
      TtsVendorSetting(vendor: TtsVendor.gemini, updatedAt: _after),
    );
    await pending;
    expect(viewModel.isBusy, isFalse);
  });

  test('같은 벤더를 다시 고르면 서버를 부르지 않는다', () async {
    stubGet(TtsVendor.gemini);

    await viewModel.load();
    final ok = await viewModel.change(TtsVendor.gemini);

    expect(ok, isTrue);
    // 바뀐 것이 없는데 감사 로그에 줄이 쌓이면 변경 이력을 세는 데 방해가 된다.
    verifyNever(() => repository.updateTtsVendor(any()));
    expect(viewModel.setting?.updatedAt, _before);
  });

  group('벤더 코드 해석', () {
    test('서버 코드를 그대로 맞춘다', () {
      expect(TtsVendor.fromCode('OPENAI'), TtsVendor.openai);
      expect(TtsVendor.fromCode('GEMINI'), TtsVendor.gemini);
      expect(TtsVendor.fromCode('CHIRP3'), TtsVendor.chirp3);
      // 대조군. 아무 코드나 통과시키는 것이 아니다.
      expect(TtsVendor.fromCode('GEMINI'), isNot(TtsVendor.openai));
    });

    test('모르는 코드와 빈 값은 기본값으로 떨어진다', () {
      // 서버가 벤더를 늘려도 화면이 죽지 않아야 한다. 이 화면이 안 뜨면
      // 되돌릴 방법까지 같이 사라진다.
      expect(TtsVendor.fromCode('ELEVENLABS'), TtsVendor.openai);
      expect(TtsVendor.fromCode(null), TtsVendor.openai);
      expect(TtsVendor.fromCode(''), TtsVendor.openai);
    });
  });
}

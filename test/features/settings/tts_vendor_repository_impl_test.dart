import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:goodquestion_admin/core/error/failure.dart';
import 'package:goodquestion_admin/core/network/dio_client.dart';
import 'package:goodquestion_admin/features/settings/data/tts_vendor_repository_impl.dart';
import 'package:goodquestion_admin/features/settings/domain/entities/tts_vendor.dart';

/// **관리자 백엔드와 맺은 계약을 재는 유일한 자리입니다.**
///
/// 다른 설정 테스트는 `TtsVendorRepository` **인터페이스**를 가짜로 갈아끼우므로
/// [TtsVendorRepositoryImpl] 이 통째로 우회됩니다. 그래서 경로를 `tts_vendor` 로,
/// 메서드를 POST 로, 본문 키를 `ttsVendor` 로 **셋 다 동시에** 틀리게 바꿔도
/// 나머지 테스트는 전부 초록이었습니다(실측). 컴파일도 통과하고, 콘솔에서만
/// 조용히 404 가 납니다.
///
/// 여기서는 Dio 의 어댑터를 가로채 **실제로 나가는 요청**을 뜯어봅니다.
/// 네트워크는 타지 않습니다.
class _RecordingAdapter implements HttpClientAdapter {
  _RecordingAdapter(this._respond);

  final ResponseBody Function(RequestOptions options) _respond;

  RequestOptions? lastRequest;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastRequest = options;
    return _respond(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _json(Map<String, Object?> body, {int status = 200}) =>
    ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: <String, List<String>>{
        Headers.contentTypeHeader: <String>[Headers.jsonContentType],
      },
    );

void main() {
  late _RecordingAdapter adapter;
  late TtsVendorRepositoryImpl repository;

  /// 응답을 바꿔 가며 저장소를 다시 세웁니다.
  void give(ResponseBody Function(RequestOptions options) respond) {
    adapter = _RecordingAdapter(respond);
    final Dio dio = Dio()..httpClientAdapter = adapter;
    repository = TtsVendorRepositoryImpl(DioClient(dio: dio));
  }

  group('조회', () {
    test('GET 으로 /settings/tts-vendor 를 부른다', () async {
      give((_) => _json({'vendor': 'GEMINI', 'updatedAt': null}));

      await repository.getTtsVendor();

      expect(adapter.lastRequest!.method, 'GET');
      expect(adapter.lastRequest!.path, '/settings/tts-vendor');
    });

    test('응답의 vendor 와 updatedAt 을 그대로 읽는다', () async {
      give(
        (_) => _json({'vendor': 'CHIRP3', 'updatedAt': '2026-08-16T06:37:44Z'}),
      );

      final TtsVendorSetting setting = await repository.getTtsVendor();

      expect(setting.vendor, TtsVendor.chirp3);
      // 서버는 UTC 로 준다. 화면에는 현지 시각으로 나가야 한다.
      expect(setting.updatedAt!.isUtc, isFalse);
      expect(setting.updatedAt!.toUtc(), DateTime.utc(2026, 8, 16, 6, 37, 44));
    });

    /// 설정 행이 아직 없으면 서버가 `updatedAt: null` 로 준다
    /// (`new TtsVendorView(OPENAI, null)`). 여기서 깨지면 **한 번도 안 바꾼
    /// 환경에서 화면이 통째로 안 뜬다** — 즉 첫 사용자가 정확히 밟는다.
    test('updatedAt 이 null 이어도 깨지지 않는다', () async {
      give((_) => _json({'vendor': 'OPENAI', 'updatedAt': null}));

      final TtsVendorSetting setting = await repository.getTtsVendor();

      expect(setting.vendor, TtsVendor.openai);
      expect(setting.updatedAt, isNull);
    });
  });

  group('변경', () {
    test('PUT 으로 부르고 본문에 vendor 를 대문자 코드로 싣는다', () async {
      give((_) => _json({'vendor': 'GEMINI', 'updatedAt': null}));

      await repository.updateTtsVendor(TtsVendor.gemini);

      final RequestOptions request = adapter.lastRequest!;
      expect(request.method, 'PUT');
      expect(request.path, '/settings/tts-vendor');
      // 서버는 record TtsVendorChangeRequest(@NotNull TtsVendor vendor) 다.
      // 키 이름과 enum 이름이 정확히 맞아야 400 이 아니다.
      expect(request.data, {'vendor': 'GEMINI'});
    });

    test('벤더 셋의 코드가 서버 enum 이름과 같다', () async {
      const Map<TtsVendor, String> expected = <TtsVendor, String>{
        TtsVendor.openai: 'OPENAI',
        TtsVendor.gemini: 'GEMINI',
        TtsVendor.chirp3: 'CHIRP3',
      };

      for (final MapEntry<TtsVendor, String> entry in expected.entries) {
        give((_) => _json({'vendor': entry.value, 'updatedAt': null}));

        await repository.updateTtsVendor(entry.key);

        expect(adapter.lastRequest!.data, {'vendor': entry.value});
      }
    });

    test('서버가 거절하면 Failure 로 바꿔 던진다', () async {
      give((_) => _json({'message': '안 됨'}, status: 400));

      await expectLater(
        repository.updateTtsVendor(TtsVendor.gemini),
        throwsA(isA<Failure>()),
      );
    });
  });

  /// 대조군. 위 단언들이 "아무것도 안 재고 통과"하는 것이 아님을 못박습니다 —
  /// 어댑터가 요청을 실제로 받고 있고, 다른 경로를 부르면 다른 값이 잡혀야 합니다.
  test('대조군 — 다른 경로를 부르면 기록된 경로가 달라진다', () async {
    give((_) => _json({'ok': true}));

    await DioClient(
      dio: Dio()..httpClientAdapter = adapter,
    ).get('/settings/nope', parse: (_) => null);

    expect(adapter.lastRequest!.path, isNot('/settings/tts-vendor'));
  });
}

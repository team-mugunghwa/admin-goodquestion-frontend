import '../entities/tts_vendor.dart';

abstract class TtsVendorRepository {
  Future<TtsVendorSetting> getTtsVendor();

  /// 벤더를 바꾸고 바뀐 결과를 돌려받습니다. 서버가 누가 언제 어느 벤더로 바꿨는지를
  /// 감사 로그에 남깁니다.
  Future<TtsVendorSetting> updateTtsVendor(TtsVendor vendor);
}

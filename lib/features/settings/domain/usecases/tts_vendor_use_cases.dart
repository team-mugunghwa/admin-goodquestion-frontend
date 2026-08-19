import '../entities/tts_vendor.dart';
import '../repositories/tts_vendor_repository.dart';

/// 음성 합성 벤더 설정 UseCase 모음.
class GetTtsVendorUseCase {
  const GetTtsVendorUseCase(this._repository);

  final TtsVendorRepository _repository;

  Future<TtsVendorSetting> call() => _repository.getTtsVendor();
}

class UpdateTtsVendorUseCase {
  const UpdateTtsVendorUseCase(this._repository);

  final TtsVendorRepository _repository;

  Future<TtsVendorSetting> call(TtsVendor vendor) =>
      _repository.updateTtsVendor(vendor);
}

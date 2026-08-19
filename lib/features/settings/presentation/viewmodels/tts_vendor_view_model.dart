import '../../../../core/presentation/base_view_model.dart';
import '../../domain/entities/tts_vendor.dart';
import '../../domain/usecases/tts_vendor_use_cases.dart';

/// 음성 합성 벤더 설정.
///
/// 저장 버튼이 없는 화면이라 "고른 값"과 "서버에 들어간 값"이 잠깐 어긋납니다.
/// 그 어긋난 구간을 여기서만 다룹니다 - View 가 자기 상태로 들고 있으면 실패했을 때
/// 무엇으로 되돌려야 하는지 알 수 없습니다.
class TtsVendorViewModel extends BaseViewModel {
  TtsVendorViewModel({
    required GetTtsVendorUseCase getTtsVendor,
    required UpdateTtsVendorUseCase updateTtsVendor,
  }) : _getTtsVendor = getTtsVendor,
       _updateTtsVendor = updateTtsVendor;

  final GetTtsVendorUseCase _getTtsVendor;
  final UpdateTtsVendorUseCase _updateTtsVendor;

  TtsVendorSetting? _setting;

  /// 조회 전에는 비어 있습니다. 조회에 성공한 뒤에만 화면이 이 값을 그립니다.
  TtsVendorSetting? get setting => _setting;

  Future<void> load() => guard(() async {
    _setting = await _getTtsVendor();
  });

  /// 고른 벤더를 곧바로 저장합니다.
  ///
  /// 저장이 도는 동안 [isBusy] 가 올라갑니다. **컨트롤을 잠그는 것은 View 의
  /// 몫입니다** - 여기서 같은 요청을 걸러 버리면 화면이 안 잠겨 있어도 테스트가
  /// 통과해 버려서, 두 번 눌림을 막고 있는지 아무도 확인하지 못하게 됩니다.
  ///
  /// @return 성공 여부. 실패하면 [errorMessage] 에 서버가 준 이유가 담기고
  /// 벤더는 고르기 전 값으로 돌아갑니다.
  Future<bool> change(TtsVendor next) async {
    final previous = _setting;

    // 같은 값을 다시 고르면 서버를 부르지 않습니다. 바뀐 것이 없는데 감사 로그에
    // 한 줄이 남으면 나중에 "언제부터 이 벤더였나"를 세는 데 방해가 됩니다.
    if (previous != null && previous.vendor == next) return true;

    // 누른 즉시 컨트롤이 움직여야 저장 버튼이 없다는 것이 납득됩니다. 응답을
    // 기다린 뒤에 움직이면 눌러도 반응이 없는 화면으로 보입니다.
    // 시각은 아직 옛 값이지만, 저장이 도는 동안 화면은 시각 대신 진행 중임을
    // 보여 주므로 옛 시각이 새 벤더의 것으로 읽힐 일은 없습니다.
    _setting = TtsVendorSetting(vendor: next, updatedAt: previous?.updatedAt);
    safeNotify();

    final ok = await runTask(() async {
      _setting = await _updateTtsVendor(next);
    });

    if (!ok) {
      // 실패했는데 고른 값이 화면에 남아 있으면, 화면과 서버가 서로 다른 벤더를
      // 가리킨 채로 굳습니다. 되돌린 사실은 View 가 스낵바로 알립니다.
      _setting = previous;
      safeNotify();
    }
    return ok;
  }
}

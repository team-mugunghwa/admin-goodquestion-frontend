import 'package:flutter/foundation.dart';

import '../error/failure.dart';
import '../state/view_state.dart';

/// 모든 ViewModel 의 부모.
///
/// ## 규칙
/// - `package:flutter/material.dart` 를 import 하지 않습니다. (`foundation.dart` 만)
/// - **`BuildContext` 를 필드로 갖지 않습니다.** 화면 이동·스낵바가 필요하면
///   ViewModel 은 상태만 바꾸고 View 가 반응하게 하세요. 그래야 단위 테스트가 됩니다.
/// - DTO 를 들고 있지 않습니다. domain Entity 만 보관합니다.
abstract class BaseViewModel extends ChangeNotifier {
  ViewState _state = ViewState.idle;
  String? _errorMessage;
  bool _disposed = false;

  /// 목록을 이미 그린 상태에서 저장/삭제 같은 조작이 도는 중인지.
  ///
  /// [state] 와 나눈 이유가 있습니다. 저장 중에 [state] 를 loading 으로 바꾸면
  /// 화면이 통째로 스피너로 바뀌어 방금까지 보던 표가 사라집니다. 관리자 화면에서는
  /// 표를 그대로 두고 버튼만 비활성으로 만드는 쪽이 맞습니다.
  bool _busy = false;

  ViewState get state => _state;
  String? get errorMessage => _errorMessage;

  bool get isLoading => _state.isLoading;
  bool get isBusy => _busy;

  @protected
  void setLoading() => _setState(ViewState.loading, null);

  @protected
  void setSuccess() => _setState(ViewState.success, null);

  @protected
  void setError(Object error) => _setState(
    ViewState.error,
    error is Failure ? error.message : Failure.fromException(error).message,
  );

  void _setState(ViewState next, String? message) {
    _state = next;
    _errorMessage = message;
    safeNotify();
  }

  /// dispose 이후에 `notifyListeners()` 를 부르면 앱이 죽습니다.
  /// 요청이 끝나기 전에 다른 메뉴로 이동하면 실제로 자주 발생합니다.
  @protected
  void safeNotify() {
    if (_disposed) return;
    notifyListeners();
  }

  /// 화면 전체를 채우는 조회. 로딩 → 실행 → 성공/실패.
  @protected
  Future<void> guard(Future<void> Function() action) async {
    setLoading();
    try {
      await action();
      setSuccess();
    } catch (e) {
      setError(e);
    }
  }

  /// 이미 그려진 화면 위에서 도는 조작(저장·삭제·상태 변경).
  ///
  /// 화면을 스피너로 덮지 않고 [isBusy] 만 올립니다. 실패하면 [errorMessage] 에
  /// 담고 `false` 를 돌려주므로, View 는 그 값으로 스낵바를 띄우면 됩니다.
  ///
  /// @return 성공 여부
  @protected
  Future<bool> runTask(Future<void> Function() action) async {
    _busy = true;
    _errorMessage = null;
    safeNotify();
    try {
      await action();
      return true;
    } catch (e) {
      _errorMessage = e is Failure
          ? e.message
          : Failure.fromException(e).message;
      return false;
    } finally {
      _busy = false;
      safeNotify();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

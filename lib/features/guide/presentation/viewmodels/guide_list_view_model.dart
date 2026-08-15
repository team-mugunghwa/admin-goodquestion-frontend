import '../../../../core/domain/content_status.dart';
import '../../../../core/presentation/base_view_model.dart';
import '../../domain/entities/guide.dart';
import '../../domain/usecases/guide_use_cases.dart';

class GuideListViewModel extends BaseViewModel {
  GuideListViewModel({
    required GetGuidesUseCase getGuides,
    required CreateGuideUseCase createGuide,
    required UpdateGuideUseCase updateGuide,
    required ReorderGuidesUseCase reorderGuides,
    required DeleteGuideUseCase deleteGuide,
  }) : _getGuides = getGuides,
       _createGuide = createGuide,
       _updateGuide = updateGuide,
       _reorderGuides = reorderGuides,
       _deleteGuide = deleteGuide;

  final GetGuidesUseCase _getGuides;
  final CreateGuideUseCase _createGuide;
  final UpdateGuideUseCase _updateGuide;
  final ReorderGuidesUseCase _reorderGuides;
  final DeleteGuideUseCase _deleteGuide;

  List<Guide> _guides = const [];
  GuideCategory? _category;
  ContentStatus? _status;

  List<Guide> get guides => _guides;
  GuideCategory? get category => _category;
  ContentStatus? get status => _status;

  /// 카테고리별로 묶은 목록. 화면이 이 단위로 섹션을 그립니다.
  ///
  /// 서버가 이미 (카테고리, 순서)로 정렬해 주므로 여기서는 나누기만 합니다.
  Map<GuideCategory, List<Guide>> get grouped {
    final map = <GuideCategory, List<Guide>>{};
    for (final guide in _guides) {
      map.putIfAbsent(guide.category, () => []).add(guide);
    }
    return map;
  }

  Future<void> load() => guard(() async {
    _guides = await _getGuides(category: _category, status: _status);
  });

  Future<void> changeCategory(GuideCategory? category) {
    _category = category;
    return load();
  }

  Future<void> changeStatus(ContentStatus? status) {
    _status = status;
    return load();
  }

  Future<bool> create({
    required GuideCategory category,
    required String title,
    required String content,
    required ContentStatus status,
  }) async {
    final ok = await runTask(
      () => _createGuide(
        category: category,
        title: title,
        content: content,
        status: status,
      ),
    );
    if (ok) await load();
    return ok;
  }

  Future<bool> update({
    required String guideId,
    GuideCategory? category,
    String? title,
    String? content,
    ContentStatus? status,
  }) async {
    final ok = await runTask(
      () => _updateGuide(
        guideId: guideId,
        category: category,
        title: title,
        content: content,
        status: status,
      ),
    );
    if (ok) await load();
    return ok;
  }

  /// 드래그로 정렬한 결과를 반영합니다.
  ///
  /// 화면이 이미 새 순서로 그려진 상태이므로, 서버 응답을 기다리는 동안 목록을
  /// 되돌리지 않습니다. 실패하면 [load] 로 서버 상태를 다시 가져와 맞춥니다 -
  /// 실패한 채로 화면만 바뀐 상태가 남는 것이 가장 나쁩니다.
  Future<bool> reorder({
    required GuideCategory category,
    required List<String> guideIds,
  }) async {
    final ok = await runTask(
      () => _reorderGuides(category: category, guideIds: guideIds),
    );
    await load();
    return ok;
  }

  Future<bool> delete(String guideId) async {
    final ok = await runTask(() => _deleteGuide(guideId));
    if (ok) await load();
    return ok;
  }
}

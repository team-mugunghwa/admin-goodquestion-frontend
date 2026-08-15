import '../../../../core/domain/content_status.dart';
import '../entities/guide.dart';

abstract class GuideRepository {
  /// 페이징이 없습니다. 순서를 보며 편집하는 화면이라 페이지를 넘겨 가며 순서를
  /// 맞출 수 없습니다. 서버도 전부 내리도록 되어 있습니다.
  Future<List<Guide>> getGuides({GuideCategory? category, ContentStatus? status});

  Future<Guide> createGuide({
    required GuideCategory category,
    required String title,
    required String content,
    required ContentStatus status,
  });

  Future<Guide> updateGuide({
    required String guideId,
    GuideCategory? category,
    String? title,
    String? content,
    ContentStatus? status,
  });

  /// 순서를 통째로 다시 매깁니다. 배열의 위치가 곧 순서입니다.
  ///
  /// "위로 한 칸" 같은 상대 조작으로 두지 않은 이유: 여러 관리자가 동시에 만졌을 때
  /// 어긋난 순서로 수렴합니다. 화면에서 정렬한 결과 전체를 보내는 쪽이 안전합니다.
  Future<List<Guide>> reorder({
    required GuideCategory category,
    required List<String> guideIds,
  });

  Future<void> deleteGuide(String guideId);
}

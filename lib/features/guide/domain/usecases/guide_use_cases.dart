import '../../../../core/domain/content_status.dart';
import '../entities/guide.dart';
import '../repositories/guide_repository.dart';

/// 이용안내 UseCase 모음.

class GetGuidesUseCase {
  const GetGuidesUseCase(this._repository);
  final GuideRepository _repository;

  Future<List<Guide>> call({GuideCategory? category, ContentStatus? status}) =>
      _repository.getGuides(category: category, status: status);
}

class CreateGuideUseCase {
  const CreateGuideUseCase(this._repository);
  final GuideRepository _repository;

  Future<Guide> call({
    required GuideCategory category,
    required String title,
    required String content,
    required ContentStatus status,
  }) => _repository.createGuide(
    category: category,
    title: title,
    content: content,
    status: status,
  );
}

class UpdateGuideUseCase {
  const UpdateGuideUseCase(this._repository);
  final GuideRepository _repository;

  Future<Guide> call({
    required String guideId,
    GuideCategory? category,
    String? title,
    String? content,
    ContentStatus? status,
  }) => _repository.updateGuide(
    guideId: guideId,
    category: category,
    title: title,
    content: content,
    status: status,
  );
}

class ReorderGuidesUseCase {
  const ReorderGuidesUseCase(this._repository);
  final GuideRepository _repository;

  Future<List<Guide>> call({
    required GuideCategory category,
    required List<String> guideIds,
  }) => _repository.reorder(category: category, guideIds: guideIds);
}

class DeleteGuideUseCase {
  const DeleteGuideUseCase(this._repository);
  final GuideRepository _repository;

  Future<void> call(String guideId) => _repository.deleteGuide(guideId);
}

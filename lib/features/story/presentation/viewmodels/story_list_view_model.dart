import '../../../../core/config/app_config.dart';
import '../../../../core/network/page_result.dart';
import '../../../../core/presentation/base_view_model.dart';
import '../../domain/entities/story.dart';
import '../../domain/usecases/story_use_cases.dart';

class StoryListViewModel extends BaseViewModel {
  StoryListViewModel({
    required GetStoriesUseCase getStories,
    required DeleteStoryUseCase deleteStory,
  }) : _getStories = getStories,
       _deleteStory = deleteStory;

  final GetStoriesUseCase _getStories;
  final DeleteStoryUseCase _deleteStory;

  PageResult<StorySummary> _stories = const PageResult.empty();
  StoryStatus? _status;
  String _keyword = '';

  PageResult<StorySummary> get stories => _stories;
  StoryStatus? get status => _status;
  String get keyword => _keyword;

  Future<void> load({int page = 0}) => guard(() async {
    _stories = await _getStories(
      status: _status,
      keyword: _keyword,
      page: page,
      size: AppConfig.defaultPageSize,
    );
  });

  Future<void> changeStatus(StoryStatus? status) {
    _status = status;
    return load();
  }

  Future<void> search(String keyword) {
    _keyword = keyword.trim();
    return load();
  }

  Future<bool> delete(String storyId) async {
    final ok = await runTask(() => _deleteStory(storyId));
    if (ok) await load(page: _stories.page);
    return ok;
  }
}

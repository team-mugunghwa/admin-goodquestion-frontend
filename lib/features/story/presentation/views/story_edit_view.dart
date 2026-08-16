import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/di/injector.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/state/view_state.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_dialogs.dart';
import '../../../../core/widgets/app_form.dart';
import '../../../../core/widgets/app_page.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../domain/entities/story.dart';
import '../../domain/usecases/story_use_cases.dart';
import '../viewmodels/story_edit_view_model.dart';
import '../widgets/character_edit_dialog.dart';
import '../widgets/scene_edit_dialog.dart';

/// 이야기 편집. 본문 / 장면 / 캐릭터를 탭으로 나눕니다.
///
/// 새 이야기는 본문 탭만 보입니다. 장면과 캐릭터는 이야기가 저장돼 id 가 생긴
/// 뒤에야 붙일 수 있습니다.
class StoryEditView extends StatelessWidget {
  const StoryEditView({this.storyId, super.key});

  final String? storyId;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      key: ValueKey(storyId),
      create: (_) => StoryEditViewModel(
        getStory: getIt<GetStoryUseCase>(),
        saveStory: getIt<SaveStoryUseCase>(),
        getScenes: getIt<GetScenesUseCase>(),
        saveScene: getIt<SaveSceneUseCase>(),
        reorderScenes: getIt<ReorderScenesUseCase>(),
        deleteScene: getIt<DeleteSceneUseCase>(),
        getCharacters: getIt<GetCharactersUseCase>(),
        saveCharacter: getIt<SaveCharacterUseCase>(),
        deleteCharacter: getIt<DeleteCharacterUseCase>(),
        getTopics: getIt<GetTopicsUseCase>(),
        storyId: storyId,
      )..load(),
      child: const _StoryEditBody(),
    );
  }
}

class _StoryEditBody extends StatefulWidget {
  const _StoryEditBody();

  @override
  State<_StoryEditBody> createState() => _StoryEditBodyState();
}

class _StoryEditBodyState extends State<_StoryEditBody>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController = TabController(length: 3, vsync: this);
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _summaryController = TextEditingController();
  final _childRoleController = TextEditingController();
  final _introController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _minutesController = TextEditingController();
  final _topicsController = TextEditingController();
  String _difficulty = 'EASY';
  bool _filled = false;

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    _summaryController.dispose();
    _childRoleController.dispose();
    _introController.dispose();
    _imageUrlController.dispose();
    _minutesController.dispose();
    _topicsController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      // 검증에 걸린 항목은 본문 탭에만 있습니다. 다른 탭을 보고 있으면
      // 왜 저장이 안 되는지 알 수 없습니다.
      _tabController.animateTo(0);
      return;
    }

    final vm = context.read<StoryEditViewModel>();
    if (vm.status == StoryStatus.published && !vm.canPublish) {
      showResultSnackBar(
        context,
        success: false,
        message: '장면이 없는 이야기는 공개할 수 없습니다. 장면을 먼저 추가해 주세요.',
      );
      return;
    }

    final wasNew = vm.isNew;
    vm.changeTopics(
      _topicsController.text
          .split(',')
          .map((value) => value.trim())
          .where((value) => value.isNotEmpty)
          .toList(),
    );
    final saved = await vm.saveStory(
      title: _titleController.text.trim(),
      summary: _summaryController.text.trim(),
      childRole: _childRoleController.text.trim(),
      intro: _introController.text.trim(),
      imageUrl: _imageUrlController.text.trim(),
      difficulty: _difficulty,
      estimatedMinutes: int.tryParse(_minutesController.text),
    );
    if (!mounted) return;

    showResultSnackBar(
      context,
      success: saved != null,
      message: saved != null ? '저장했습니다.' : (vm.errorMessage ?? '저장하지 못했습니다.'),
    );
    if (saved != null && wasNew) {
      context.go(AppRoutes.storyDetailOf(saved.id));
    }
  }

  Future<void> _addOrEditScene(StoryEditViewModel vm, {StoryScene? scene}) async {
    final draft = await showSceneEditDialog(
      context,
      scene: scene,
      characters: vm.characters,
    );
    if (draft == null || !mounted) return;

    final ok = await vm.saveScene(
      sceneId: scene?.id,
      sceneType: draft.sceneType,
      sceneDescription: draft.sceneDescription,
      characterId: draft.characterId,
      characterName: draft.characterName,
      characterOpening: draft.characterOpening,
      characterClosing: draft.characterClosing,
      sceneGoal: draft.sceneGoal,
      requiredElements: draft.requiredElements,
      preferredTurns: draft.preferredTurns,
      maxTurns: draft.maxTurns,
    );
    if (!mounted) return;
    showResultSnackBar(
      context,
      success: ok,
      message: ok ? '장면을 저장했습니다.' : (vm.errorMessage ?? '저장하지 못했습니다.'),
    );
  }

  Future<void> _addOrEditCharacter(
    StoryEditViewModel vm, {
    StoryCharacter? character,
  }) async {
    final draft = await showCharacterEditDialog(context, character: character);
    if (draft == null || !mounted) return;

    final ok = await vm.saveCharacter(
      characterId: character?.id,
      characterKey: draft.characterKey,
      name: draft.name,
      personality: draft.personality,
      guidanceStyle: draft.guidanceStyle,
      ttsVoice: draft.ttsVoice,
      ttsStyle: draft.ttsStyle,
      expressionKeys: draft.expressionKeys,
    );
    if (!mounted) return;
    showResultSnackBar(
      context,
      success: ok,
      message: ok ? '캐릭터를 저장했습니다.' : (vm.errorMessage ?? '저장하지 못했습니다.'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<StoryEditViewModel>();

    if (!_filled && vm.story != null) {
      final story = vm.story!;
      _titleController.text = story.title;
      _summaryController.text = story.summary;
      _childRoleController.text = story.childRole ?? '';
      _introController.text = story.intro ?? '';
      _imageUrlController.text = story.imageUrl ?? '';
      _minutesController.text = story.estimatedMinutes?.toString() ?? '';
      _topicsController.text = story.topics.join(', ');
      _difficulty = story.difficulty;
      _filled = true;
    }

    return AppPage(
      title: vm.isNew ? '이야기 추가' : (vm.story?.title ?? '이야기 수정'),
      backRoute: AppRoutes.stories,
      description: vm.isNew
          ? '먼저 이야기를 저장한 뒤 장면과 캐릭터를 추가할 수 있습니다.'
          : '장면 ${vm.scenes.length}개 / 진행 기록 ${vm.story?.sessionCount ?? 0}건',
      scrollable: false,
      actions: [
        FilledButton(
          onPressed: vm.isBusy ? null : _save,
          child: Text(vm.isBusy ? '저장 중...' : '저장'),
        ),
      ],
      child: AppStateView(
        state: vm.state == ViewState.success || !vm.isNew
            ? vm.state
            : ViewState.success,
        errorMessage: vm.errorMessage,
        onRetry: () => context.read<StoryEditViewModel>().load(),
        builder: (context) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelStyle: AppTypography.bodyStrong,
              tabs: [
                const Tab(text: '이야기 정보'),
                Tab(text: '장면 (${vm.scenes.length})'),
                Tab(text: '캐릭터 (${vm.characters.length})'),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  SingleChildScrollView(child: _storyForm(vm)),
                  SingleChildScrollView(child: _sceneTab(vm)),
                  SingleChildScrollView(child: _characterTab(vm)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _storyForm(StoryEditViewModel vm) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppSizes.formMaxWidth),
        child: AppCard(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppField(
                  label: '제목',
                  required: true,
                  child: TextFormField(
                    controller: _titleController,
                    maxLength: 100,
                    validator: (value) => (value == null || value.trim().isEmpty)
                        ? '제목을 입력해 주세요.'
                        : null,
                  ),
                ),
                AppField(
                  label: '줄거리',
                  required: true,
                  hint: '목록과 상세 화면에 보이는 소개 문장입니다.',
                  child: TextFormField(
                    controller: _summaryController,
                    maxLines: 3,
                    validator: (value) => (value == null || value.trim().isEmpty)
                        ? '줄거리를 입력해 주세요.'
                        : null,
                  ),
                ),
                AppField(
                  label: '아이가 맡는 역할',
                  hint: '상세 화면에서 "너는 ~야" 하고 알려 주는 문구입니다.',
                  child: TextFormField(controller: _childRoleController),
                ),
                AppField(
                  label: '도입 소개',
                  hint: '이야기를 시작하기 전에 들려주는 상황 설명입니다.',
                  child: TextFormField(controller: _introController, maxLines: 3),
                ),
                AppField(
                  label: '주제',
                  hint: '쉼표로 구분합니다. 없는 주제는 자동으로 만들어집니다. '
                      '기존 주제: ${vm.topics.map((t) => t.name).join(", ")}',
                  child: TextFormField(
                    controller: _topicsController,
                    decoration: const InputDecoration(hintText: '다름, 용기'),
                  ),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: AppField(
                        label: '난이도',
                        child: DropdownButtonFormField<String>(
                          initialValue: _difficulty,
                          items: const [
                            DropdownMenuItem(value: 'EASY', child: Text('쉬움')),
                            DropdownMenuItem(value: 'NORMAL', child: Text('보통')),
                            DropdownMenuItem(value: 'HARD', child: Text('어려움')),
                          ],
                          onChanged: (value) =>
                              setState(() => _difficulty = value ?? _difficulty),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(
                      child: AppField(
                        label: '예상 소요 시간(분)',
                        child: TextFormField(
                          controller: _minutesController,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(
                      child: AppField(
                        label: '노출 상태',
                        child: DropdownButtonFormField<StoryStatus>(
                          initialValue: vm.status,
                          items: [
                            for (final entry in StoryStatus.labels.entries)
                              DropdownMenuItem(
                                value: entry.key,
                                child: Text(entry.value),
                              ),
                          ],
                          onChanged: (value) => value == null
                              ? null
                              : context
                                    .read<StoryEditViewModel>()
                                    .changeStatus(value),
                        ),
                      ),
                    ),
                  ],
                ),
                AppField(
                  label: '대표 이미지 주소',
                  child: TextFormField(controller: _imageUrlController),
                ),
                if (vm.status == StoryStatus.published && !vm.canPublish)
                  const _Notice(
                    color: AppColors.warning,
                    background: AppColors.warningSurface,
                    message: '장면이 없어 공개할 수 없습니다. 장면 탭에서 먼저 장면을 추가해 주세요.',
                  ),
                if (!vm.isNew && !(vm.story?.deletable ?? true))
                  _Notice(
                    color: AppColors.ink500,
                    background: AppColors.surfaceMuted,
                    message: '이미 진행된 기록이 ${vm.story!.sessionCount}건 있어 삭제할 수 없습니다. '
                        '노출만 멈추려면 상태를 보관으로 바꾸세요.',
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sceneTab(StoryEditViewModel vm) {
    if (vm.isNew) {
      return const AppEmptyView(
        title: '이야기를 먼저 저장해 주세요',
        description: '장면은 저장된 이야기에만 추가할 수 있습니다.',
      );
    }

    return AppCard(
      title: '장면',
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      trailing: TextButton.icon(
        onPressed: () => _addOrEditScene(vm),
        icon: const Icon(AppIcons.add, size: AppSizes.icon),
        label: const Text('장면 추가'),
      ),
      child: vm.scenes.isEmpty
          ? Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Text(
                '장면이 없습니다. 사용자가 이야기를 시작하려면 장면이 하나 이상 있어야 합니다.',
                style: AppTypography.caption,
              ),
            )
          : ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              buildDefaultDragHandles: false,
              itemCount: vm.scenes.length,
              // onReorderItem 으로 바꾸면 인덱스 보정 규칙이 달라져 순서가 한 칸씩
        // 어긋납니다. 아래 보정과 함께 한 번에 옮겨야 해서 지금은 그대로 둡니다.
        // ignore: deprecated_member_use
        onReorder: (oldIndex, newIndex) {
                final adjusted = newIndex > oldIndex ? newIndex - 1 : newIndex;
                final ids = vm.scenes.map((scene) => scene.id).toList();
                final moved = ids.removeAt(oldIndex);
                ids.insert(adjusted, moved);
                vm.reorderScenes(ids);
              },
              itemBuilder: (context, index) {
                final scene = vm.scenes[index];
                return _SceneRow(
                  key: ValueKey(scene.id),
                  index: index,
                  scene: scene,
                  onEdit: () => _addOrEditScene(vm, scene: scene),
                  onDelete: () async {
                    final confirmed = await showConfirmDialog(
                      context,
                      title: '장면을 삭제할까요?',
                      message: '${index + 1}번 장면이 지워지고 이후 장면의 순서가 당겨집니다.',
                      confirmLabel: '삭제',
                      destructive: true,
                    );
                    if (!confirmed || !mounted) return;
                    await vm.deleteScene(scene.id);
                  },
                );
              },
            ),
    );
  }

  Widget _characterTab(StoryEditViewModel vm) {
    if (vm.isNew) {
      return const AppEmptyView(
        title: '이야기를 먼저 저장해 주세요',
        description: '캐릭터는 저장된 이야기에만 추가할 수 있습니다.',
      );
    }

    return AppCard(
      title: '캐릭터',
      trailing: TextButton.icon(
        onPressed: () => _addOrEditCharacter(vm),
        icon: const Icon(AppIcons.add, size: AppSizes.icon),
        label: const Text('캐릭터 추가'),
      ),
      child: vm.characters.isEmpty
          ? Text(
              '캐릭터가 없습니다. 대화 장면을 만들려면 캐릭터가 먼저 있어야 합니다.',
              style: AppTypography.caption,
            )
          : Wrap(
              spacing: AppSpacing.lg,
              runSpacing: AppSpacing.lg,
              children: [
                for (final character in vm.characters)
                  _CharacterCard(
                    character: character,
                    onEdit: () =>
                        _addOrEditCharacter(vm, character: character),
                    onDelete: () async {
                      final confirmed = await showConfirmDialog(
                        context,
                        title: '캐릭터를 삭제할까요?',
                        message: '"${character.name}"\n\n'
                            '이 캐릭터를 쓰는 장면이 있으면 삭제되지 않습니다.',
                        confirmLabel: '삭제',
                        destructive: true,
                      );
                      if (!confirmed || !mounted) return;
                      final ok = await vm.deleteCharacter(character.id);
                      if (!mounted) return;
                      showResultSnackBar(
                        context,
                        success: ok,
                        message: ok
                            ? '캐릭터를 삭제했습니다.'
                            : (vm.errorMessage ?? '삭제하지 못했습니다.'),
                      );
                    },
                  ),
              ],
            ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({
    required this.color,
    required this.background,
    required this.message,
  });

  final Color color;
  final Color background;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Text(message, style: AppTypography.caption.copyWith(color: color)),
    );
  }
}

class _SceneRow extends StatelessWidget {
  const _SceneRow({
    required this.index,
    required this.scene,
    required this.onEdit,
    required this.onDelete,
    super.key,
  });

  final int index;
  final StoryScene scene;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.ink100)),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          ReorderableDragStartListener(
            index: index,
            child: const MouseRegion(
              cursor: SystemMouseCursors.grab,
              child: Padding(
                padding: EdgeInsets.only(right: AppSpacing.md),
                child: Icon(
                  AppIcons.dragHandle,
                  size: AppSizes.icon,
                  color: AppColors.ink400,
                ),
              ),
            ),
          ),
          SizedBox(
            width: 32,
            child: Text('${index + 1}', style: AppTypography.number),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(scene.sceneType.label, style: sceneTypeStyle(scene)),
                    const SizedBox(width: AppSpacing.sm),
                    Flexible(
                      child: Text(
                        scene.sceneDescription,
                        style: AppTypography.bodyStrong,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(sceneSubtitle(scene), style: AppTypography.caption),
              ],
            ),
          ),
          IconButton(
            tooltip: '수정',
            onPressed: onEdit,
            icon: const Icon(AppIcons.edit, size: AppSizes.icon),
            color: AppColors.ink500,
          ),
          IconButton(
            tooltip: '삭제',
            onPressed: onDelete,
            icon: const Icon(AppIcons.delete, size: AppSizes.icon),
            color: AppColors.ink500,
          ),
        ],
      ),
    );
  }
}

class _CharacterCard extends StatelessWidget {
  const _CharacterCard({
    required this.character,
    required this.onEdit,
    required this.onDelete,
  });

  final StoryCharacter character;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(character.name, style: AppTypography.bodyStrong),
              ),
              IconButton(
                tooltip: '수정',
                onPressed: onEdit,
                icon: const Icon(AppIcons.edit, size: AppSizes.icon),
                color: AppColors.ink500,
              ),
              IconButton(
                tooltip: '삭제',
                onPressed: onDelete,
                icon: const Icon(AppIcons.delete, size: AppSizes.icon),
                color: AppColors.ink500,
              ),
            ],
          ),
          Text(
            '키: ${character.characterKey}'
            '${character.ttsVoice == null ? "" : " / 보이스: ${character.ttsVoice}"}',
            style: AppTypography.caption,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            character.personality,
            style: AppTypography.caption,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

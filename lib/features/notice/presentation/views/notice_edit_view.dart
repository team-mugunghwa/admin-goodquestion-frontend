import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/domain/content_status.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/state/view_state.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formats.dart';
import '../../../../core/widgets/app_dialogs.dart';
import '../../../../core/widgets/app_form.dart';
import '../../../../core/widgets/app_page.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../domain/entities/notice.dart';
import '../../domain/usecases/notice_use_cases.dart';
import '../viewmodels/notice_edit_view_model.dart';

/// 공지 작성/수정. [noticeId] 가 null 이면 새 글입니다.
class NoticeEditView extends StatelessWidget {
  const NoticeEditView({this.noticeId, super.key});

  final String? noticeId;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      // 경로가 바뀌면(다른 공지로 이동) ViewModel 을 새로 만들어야 합니다.
      key: ValueKey(noticeId),
      create: (_) => NoticeEditViewModel(
        getNotice: getIt<GetNoticeUseCase>(),
        createNotice: getIt<CreateNoticeUseCase>(),
        updateNotice: getIt<UpdateNoticeUseCase>(),
        getRevisions: getIt<GetNoticeRevisionsUseCase>(),
        revertNotice: getIt<RevertNoticeUseCase>(),
        scheduleNotice: getIt<ScheduleNoticeUseCase>(),
        cancelSchedule: getIt<CancelNoticeScheduleUseCase>(),
        noticeId: noticeId,
      )..load(),
      child: const _NoticeEditBody(),
    );
  }
}

class _NoticeEditBody extends StatefulWidget {
  const _NoticeEditBody();

  @override
  State<_NoticeEditBody> createState() => _NoticeEditBodyState();
}

class _NoticeEditBodyState extends State<_NoticeEditBody> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();

  /// 마지막으로 폼을 채운 원본. 매 build 마다 채우면 타이핑하는 족족
  /// 되돌아가므로, 서버 내용이 실제로 달라졌을 때만 다시 채웁니다.
  /// 되돌리기가 그 경우다 - 채우지 않으면 입력칸이 예전 내용에 머문다.
  NoticeDetail? _filledFrom;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final vm = context.read<NoticeEditViewModel>();
    final wasNew = vm.isNew;
    final saved = await vm.save(
      title: _titleController.text.trim(),
      content: _contentController.text,
    );
    if (!mounted) return;

    showResultSnackBar(
      context,
      success: saved != null,
      message: saved != null
          ? '저장했습니다.'
          : (vm.errorMessage ?? '저장하지 못했습니다.'),
    );
    // 새 글이었다면 방금 만든 글의 주소로 바꿔 둡니다. 그대로 두면 저장을 한 번 더
    // 눌렀을 때 같은 공지가 두 개 만들어집니다.
    if (saved != null && wasNew) {
      context.go(AppRoutes.noticeDetailOf(saved.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<NoticeEditViewModel>();

    final loaded = vm.notice;
    if (loaded != null &&
        (_filledFrom == null ||
            _filledFrom!.title != loaded.title ||
            _filledFrom!.content != loaded.content)) {
      _titleController.text = loaded.title;
      _contentController.text = loaded.content;
    }
    if (loaded != null) _filledFrom = loaded;

    return AppPage(
      title: vm.isNew ? '공지 작성' : '공지 수정',
      backRoute: AppRoutes.notices,
      description: vm.notice == null
          ? null
          : '조회 ${Formats.count(vm.notice!.viewCount)}회 / '
                '마지막 수정 ${Formats.dateTime(vm.notice!.updatedAt)}',
      actions: [
        // 저장 전에 사용자 화면 모습을 확인한다. 실수 비용이 큰 화면이라
        // "보내기 전에 본다"가 이 화면의 기본 동선이어야 한다.
        OutlinedButton(
          onPressed: () => _NoticePreviewDialog.show(
            context,
            title: _titleController.text,
            content: _contentController.text,
            category: vm.category,
            pinned: vm.pinned,
          ),
          child: const Text('미리보기'),
        ),
        if (!vm.isNew)
          OutlinedButton(
            onPressed: () => _RevisionsDialog.show(context),
            child: const Text('수정 이력'),
          ),
        OutlinedButton(
          onPressed: () => context.go(AppRoutes.notices),
          child: const Text('취소'),
        ),
        FilledButton(
          onPressed: vm.isBusy ? null : _save,
          child: Text(vm.isBusy ? '저장 중...' : '저장'),
        ),
      ],
      child: AppStateView(
        // 새 글은 서버에서 받아올 것이 없어 조회 상태가 idle 로 남습니다.
        // 그대로 두면 화면이 계속 스피너를 그립니다.
        state: vm.isNew ? ViewState.success : vm.state,
        errorMessage: vm.errorMessage,
        onRetry: () => context.read<NoticeEditViewModel>().load(),
        builder: (context) => Center(
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
                        maxLength: 200,
                        decoration: const InputDecoration(
                          hintText: '예: 정기 점검 안내 (매주 화요일 새벽)',
                        ),
                        validator: (value) =>
                            (value == null || value.trim().isEmpty)
                            ? '제목을 입력해 주세요.'
                            : null,
                      ),
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: AppField(
                            label: '분류',
                            child: DropdownButtonFormField<NoticeCategory>(
                              initialValue: vm.category,
                              items: [
                                for (final entry
                                    in NoticeCategory.labels.entries)
                                  DropdownMenuItem(
                                    value: entry.key,
                                    child: Text(entry.value),
                                  ),
                              ],
                              onChanged: (value) => value == null
                                  ? null
                                  : context
                                        .read<NoticeEditViewModel>()
                                        .changeCategory(value),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.lg),
                        Expanded(
                          child: AppField(
                            label: '노출 상태',
                            hint: '공개로 두면 사용자 앱에 바로 보입니다.',
                            child: DropdownButtonFormField<ContentStatus>(
                              initialValue: vm.status,
                              items: [
                                for (final entry in ContentStatus.labels.entries)
                                  DropdownMenuItem(
                                    value: entry.key,
                                    child: Text(entry.value),
                                  ),
                              ],
                              onChanged: (value) => value == null
                                  ? null
                                  : context
                                        .read<NoticeEditViewModel>()
                                        .changeStatus(value),
                            ),
                          ),
                        ),
                      ],
                    ),
                    AppField(
                      label: '목록 상단 고정',
                      hint: '점검 안내처럼 기간이 지나면 내려야 하는 공지에 씁니다.',
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Switch(
                          value: vm.pinned,
                          onChanged: (value) => context
                              .read<NoticeEditViewModel>()
                              .togglePinned(value),
                        ),
                      ),
                    ),
                    AppField(
                      label: '본문',
                      required: true,
                      hint: '줄바꿈은 그대로 사용자 화면에 반영됩니다.',
                      child: TextFormField(
                        controller: _contentController,
                        maxLines: 14,
                        minLines: 10,
                        decoration: const InputDecoration(
                          hintText: '사용자에게 보일 내용을 적어 주세요.',
                        ),
                        validator: (value) =>
                            (value == null || value.trim().isEmpty)
                            ? '본문을 입력해 주세요.'
                            : null,
                      ),
                    ),
                    if (vm.status == ContentStatus.published)
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.primarySurface,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        child: Text(
                          '저장하면 사용자 앱의 공지 목록에 바로 보입니다.',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    if (!vm.isNew && vm.status == ContentStatus.draft) ...[
                      const SizedBox(height: AppSpacing.lg),
                      const _ScheduleControl(),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 사용자 앱에서 보이는 모습.
///
/// 사용자 앱의 공지 화면과 같은 구성(분류, 고정 표시, 제목, 본문, 줄바꿈 유지)을
/// 흰 카드에 재현합니다. 완전히 같은 렌더링은 아니지만, 잡으려는 실수는
/// 줄바꿈 꼬임/제목 오타/분류 잘못 같은 것이라 이 수준이면 잡힙니다.
class _NoticePreviewDialog extends StatelessWidget {
  const _NoticePreviewDialog({
    required this.title,
    required this.content,
    required this.category,
    required this.pinned,
  });

  final String title;
  final String content;
  final NoticeCategory category;
  final bool pinned;

  static Future<void> show(
    BuildContext context, {
    required String title,
    required String content,
    required NoticeCategory category,
    required bool pinned,
  }) => showDialog<void>(
    context: context,
    builder: (_) => _NoticePreviewDialog(
      title: title,
      content: content,
      category: category,
      pinned: pinned,
    ),
  );

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('미리보기'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: AppColors.ink100),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primarySurface,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Text(
                        category.label,
                        style: AppTypography.badge.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    if (pinned) ...[
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        '고정됨',
                        style: AppTypography.badge.copyWith(
                          color: AppColors.warning,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  title.trim().isEmpty ? '(제목 없음)' : title,
                  style: AppTypography.sectionTitle,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  Formats.date(DateTime.now()),
                  style: AppTypography.caption,
                ),
                const Divider(height: AppSpacing.xl),
                Text(
                  content.trim().isEmpty ? '(본문 없음)' : content,
                  style: AppTypography.body,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('닫기'),
        ),
      ],
    );
  }
}

/// 예약 공개 조작. 초안인 기존 공지에서만 보입니다.
class _ScheduleControl extends StatelessWidget {
  const _ScheduleControl();

  Future<void> _pick(BuildContext context) async {
    final vm = context.read<NoticeEditViewModel>();
    final now = DateTime.now();

    final date = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (date == null || !context.mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 10, minute: 0),
    );
    if (time == null || !context.mounted) return;

    final at = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    if (!at.isAfter(DateTime.now())) {
      showResultSnackBar(context, success: false, message: '앞으로의 시각을 골라 주세요.');
      return;
    }

    final ok = await vm.schedule(at);
    if (!context.mounted) return;
    showResultSnackBar(
      context,
      success: ok,
      message: ok
          ? '${Formats.dateTime(at)} 에 공개되도록 예약했습니다.'
          : (vm.errorMessage ?? '예약하지 못했습니다.'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<NoticeEditViewModel>();
    final scheduledAt = vm.notice?.scheduledPublishAt;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              scheduledAt == null
                  ? '예약 공개: 정해 둔 시각에 자동으로 공개됩니다. 밤 12시 공개를 위해 밤에 접속하지 않아도 됩니다.'
                  : '${Formats.dateTime(scheduledAt)} 에 자동 공개됩니다.',
              style: AppTypography.caption.copyWith(
                color: scheduledAt == null ? AppColors.ink500 : AppColors.primary,
                fontWeight:
                    scheduledAt == null ? FontWeight.w400 : FontWeight.w600,
              ),
            ),
          ),
          if (scheduledAt == null)
            OutlinedButton(
              onPressed: vm.isBusy ? null : () => _pick(context),
              child: const Text('예약 걸기'),
            )
          else ...[
            TextButton(
              onPressed: vm.isBusy ? null : () => _pick(context),
              child: const Text('시각 바꾸기'),
            ),
            TextButton(
              onPressed: vm.isBusy
                  ? null
                  : () async {
                      final vmRead = context.read<NoticeEditViewModel>();
                      final ok = await vmRead.cancelSchedule();
                      if (!context.mounted) return;
                      showResultSnackBar(
                        context,
                        success: ok,
                        message: ok
                            ? '예약을 취소했습니다.'
                            : (vmRead.errorMessage ?? '취소하지 못했습니다.'),
                      );
                    },
              child: const Text('예약 취소'),
            ),
          ],
        ],
      ),
    );
  }
}

/// 수정 이력. 최신이 위이고, 항목을 펼쳐 그 시점 본문을 보고 되돌립니다.
class _RevisionsDialog extends StatelessWidget {
  const _RevisionsDialog({required this.viewModel});

  final NoticeEditViewModel viewModel;

  static Future<void> show(BuildContext context) {
    final vm = context.read<NoticeEditViewModel>();
    return showDialog<void>(
      context: context,
      builder: (_) => _RevisionsDialog(viewModel: vm),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('수정 이력'),
      content: SizedBox(
        width: 560,
        child: FutureBuilder<List<NoticeRevision>>(
          future: viewModel.loadRevisions(),
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const SizedBox(
                height: 120,
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              );
            }
            final revisions = snapshot.data ?? const <NoticeRevision>[];
            if (revisions.isEmpty) {
              return Text(
                '아직 이력이 없습니다. 내용을 고쳐 저장하면 바꾸기 전 내용이 여기 남습니다.',
                style: AppTypography.caption,
              );
            }
            return SizedBox(
              height: 400,
              child: ListView.builder(
                itemCount: revisions.length,
                itemBuilder: (context, index) {
                  final revision = revisions[index];
                  return ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    title: Text(revision.title, style: AppTypography.body),
                    subtitle: Text(
                      '${revision.editedByEmail} / ${Formats.dateTime(revision.createdAt)}',
                      style: AppTypography.caption,
                    ),
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Text(
                            revision.content,
                            style: AppTypography.body,
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () async {
                            final confirmed = await showConfirmDialog(
                              context,
                              title: '이 내용으로 되돌릴까요?',
                              message:
                                  '지금 내용도 이력으로 남아 다시 돌아올 수 있습니다. 공개 여부는 바뀌지 않습니다.',
                              confirmLabel: '되돌리기',
                            );
                            if (!confirmed || !context.mounted) return;
                            final reverted =
                                await viewModel.revert(revision.id);
                            if (!context.mounted) return;
                            Navigator.of(context).pop();
                            showResultSnackBar(
                              context,
                              success: reverted != null,
                              message: reverted != null
                                  ? '되돌렸습니다. 저장 없이 바로 반영되어 있습니다.'
                                  : (viewModel.errorMessage ?? '되돌리지 못했습니다.'),
                            );
                          },
                          child: const Text('이 내용으로 되돌리기'),
                        ),
                      ),
                    ],
                  );
                },
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('닫기'),
        ),
      ],
    );
  }
}

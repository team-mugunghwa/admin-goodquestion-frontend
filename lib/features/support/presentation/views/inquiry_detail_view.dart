import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formats.dart';
import '../../../../core/widgets/app_dialogs.dart';
import '../../../../core/widgets/app_form.dart';
import '../../../../core/widgets/app_page.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../../core/widgets/app_status_chip.dart';
import '../../../auth/presentation/viewmodels/admin_session.dart';
import '../../domain/entities/inquiry.dart';
import '../../domain/usecases/support_use_cases.dart';
import '../viewmodels/inquiry_detail_view_model.dart';

/// 문의 상세와 답변 등록.
///
/// 이 화면이 관리자 콘솔에서 사용자에게 직접 닿는 유일한 곳입니다. 답변을 저장하면
/// 서버가 알림을 만들고 푸시를 보냅니다.
class InquiryDetailView extends StatelessWidget {
  const InquiryDetailView({required this.inquiryId, super.key});

  final String inquiryId;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      key: ValueKey(inquiryId),
      create: (_) => InquiryDetailViewModel(
        getInquiry: getIt<GetInquiryUseCase>(),
        answerInquiry: getIt<AnswerInquiryUseCase>(),
        updateAnswer: getIt<UpdateAnswerUseCase>(),
        closeInquiry: getIt<CloseInquiryUseCase>(),
        reopenInquiry: getIt<ReopenInquiryUseCase>(),
        assignInquiry: getIt<AssignInquiryUseCase>(),
        unassignInquiry: getIt<UnassignInquiryUseCase>(),
        addNote: getIt<AddInquiryNoteUseCase>(),
        getTemplates: getIt<GetReplyTemplatesUseCase>(),
        saveTemplate: getIt<SaveReplyTemplateUseCase>(),
        deleteTemplate: getIt<DeleteReplyTemplateUseCase>(),
        inquiryId: inquiryId,
      )..load(),
      child: const _InquiryDetailBody(),
    );
  }
}

class _InquiryDetailBody extends StatefulWidget {
  const _InquiryDetailBody();

  @override
  State<_InquiryDetailBody> createState() => _InquiryDetailBodyState();
}

class _InquiryDetailBodyState extends State<_InquiryDetailBody> {
  final _answerController = TextEditingController();

  /// 답변을 고치는 중인지. 이미 답변이 있으면 기본은 읽기 모드입니다 -
  /// 편집 상자를 바로 열어 두면 실수로 덮어쓰기 쉽습니다.
  bool _editing = false;
  String? _loadedAnswerFor;

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  Future<void> _submit(InquiryDetail inquiry) async {
    final content = _answerController.text.trim();
    if (content.isEmpty) {
      showResultSnackBar(context, success: false, message: '답변 내용을 입력해 주세요.');
      return;
    }

    final vm = context.read<InquiryDetailViewModel>();
    final isEdit = inquiry.hasAnswer;
    final ok = isEdit
        ? await vm.editAnswer(content)
        : await vm.submitAnswer(content);
    if (!mounted) return;

    setState(() => _editing = false);
    showResultSnackBar(
      context,
      success: ok,
      message: ok
          ? (isEdit ? '답변을 수정했습니다. 알림은 다시 가지 않습니다.' : '답변을 등록했습니다. 사용자에게 알림이 갑니다.')
          : (vm.errorMessage ?? '저장하지 못했습니다.'),
    );
  }

  Future<void> _toggleClose(InquiryDetail inquiry) async {
    final vm = context.read<InquiryDetailViewModel>();
    if (inquiry.isClosed) {
      final ok = await vm.reopen();
      if (!mounted) return;
      showResultSnackBar(
        context,
        success: ok,
        message: ok ? '문의를 다시 열었습니다.' : (vm.errorMessage ?? '처리하지 못했습니다.'),
      );
      return;
    }

    final confirmed = await showConfirmDialog(
      context,
      title: '문의를 종료할까요?',
      message: '종료하면 답변을 등록할 수 없습니다. 중복 문의나 문의가 아닌 글에 씁니다.\n'
          '필요하면 다시 열 수 있습니다.',
      confirmLabel: '종료',
    );
    if (!confirmed || !mounted) return;
    final ok = await vm.close();
    if (!mounted) return;
    showResultSnackBar(
      context,
      success: ok,
      message: ok ? '문의를 종료했습니다.' : (vm.errorMessage ?? '처리하지 못했습니다.'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<InquiryDetailViewModel>();
    final inquiry = vm.inquiry;

    // 서버에서 받은 답변을 편집 상자에 한 번만 채웁니다.
    if (inquiry?.answer != null && _loadedAnswerFor != inquiry!.answer!.id) {
      _answerController.text = inquiry.answer!.content;
      _loadedAnswerFor = inquiry.answer!.id;
    }

    return AppPage(
      title: '문의 상세',
      backRoute: AppRoutes.inquiries,
      actions: [
        if (inquiry != null)
          OutlinedButton(
            onPressed: vm.isBusy ? null : () => _toggleClose(inquiry),
            child: Text(inquiry.isClosed ? '다시 열기' : '문의 종료'),
          ),
      ],
      child: AppStateView(
        state: vm.state,
        errorMessage: vm.errorMessage,
        onRetry: () => context.read<InquiryDetailViewModel>().load(),
        builder: (context) => Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _InquiryCard(inquiry: inquiry!),
                const SizedBox(height: AppSpacing.lg),
                _AnswerCard(
                  inquiry: inquiry,
                  templates: vm.templates,
                  controller: _answerController,
                  editing: _editing || !inquiry.hasAnswer,
                  busy: vm.isBusy,
                  onEdit: () => setState(() => _editing = true),
                  onCancelEdit: () {
                    _answerController.text = inquiry.answer?.content ?? '';
                    setState(() => _editing = false);
                  },
                  onSubmit: () => _submit(inquiry),
                ),
                const SizedBox(height: AppSpacing.lg),
                _NotesCard(notes: inquiry.notes, busy: vm.isBusy),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InquiryCard extends StatelessWidget {
  const _InquiryCard({required this.inquiry});

  final InquiryDetail inquiry;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppStatusChip(
                label: inquiry.status.label,
                tone: inquiry.status.tone,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(inquiry.category.label, style: AppTypography.caption),
              const Spacer(),
              Text(
                Formats.dateTime(inquiry.createdAt),
                style: AppTypography.caption,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(inquiry.title, style: AppTypography.pageTitle),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Text(inquiry.parentName, style: AppTypography.bodyStrong),
              if (inquiry.parentEmail != null) ...[
                const SizedBox(width: AppSpacing.sm),
                Text(inquiry.parentEmail!, style: AppTypography.caption),
              ],
              const SizedBox(width: AppSpacing.md),
              TextButton(
                onPressed: () =>
                    context.go(AppRoutes.memberDetailOf(inquiry.parentId)),
                child: const Text('사용자 정보 보기'),
              ),
              const Spacer(),
              _AssigneeControl(inquiry: inquiry),
            ],
          ),
          const Divider(height: AppSpacing.xxl),
          // 사용자가 쓴 원문입니다. 줄바꿈을 그대로 살려야 뜻이 어긋나지 않습니다.
          SelectableText(inquiry.content, style: AppTypography.body),
        ],
      ),
    );
  }
}

class _AnswerCard extends StatelessWidget {
  const _AnswerCard({
    required this.inquiry,
    required this.templates,
    required this.controller,
    required this.editing,
    required this.busy,
    required this.onEdit,
    required this.onCancelEdit,
    required this.onSubmit,
  });

  final InquiryDetail inquiry;
  final List<ReplyTemplate> templates;
  final TextEditingController controller;
  final bool editing;
  final bool busy;
  final VoidCallback onEdit;
  final VoidCallback onCancelEdit;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    if (inquiry.isClosed && !inquiry.hasAnswer) {
      return AppCard(
        child: Text(
          '종료된 문의입니다. 답변하려면 먼저 문의를 다시 열어 주세요.',
          style: AppTypography.body.copyWith(color: AppColors.ink500),
        ),
      );
    }

    // 답변이 있고 편집 중이 아니면 읽기 모드.
    if (inquiry.hasAnswer && !editing) {
      final answer = inquiry.answer!;
      return AppCard(
        title: '등록된 답변',
        trailing: TextButton(onPressed: onEdit, child: const Text('수정')),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(answer.adminName, style: AppTypography.bodyStrong),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  Formats.dateTime(answer.updatedAt ?? answer.createdAt),
                  style: AppTypography.caption,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            SelectableText(answer.content, style: AppTypography.body),
          ],
        ),
      );
    }

    return AppCard(
      title: inquiry.hasAnswer ? '답변 수정' : '답변 등록',
      trailing: _TemplatePicker(
        inquiry: inquiry,
        templates: templates,
        controller: controller,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppField(
            label: '답변 내용',
            required: true,
            hint: inquiry.hasAnswer
                ? '수정해도 사용자에게 알림이 다시 가지 않습니다. 사용자는 앱에서 최신 내용을 봅니다.'
                : '저장하면 사용자에게 알림이 가고 앱의 문의 상세에서 이 내용을 봅니다.',
            child: TextField(
              controller: controller,
              maxLines: 10,
              minLines: 6,
              decoration: const InputDecoration(
                hintText: '안녕하세요, 굿퀘스천입니다.\n\n문의하신 내용에 대해 안내드립니다.',
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (inquiry.hasAnswer)
                TextButton(onPressed: onCancelEdit, child: const Text('취소')),
              const SizedBox(width: AppSpacing.sm),
              FilledButton(
                onPressed: busy ? null : onSubmit,
                child: Text(
                  busy
                      ? '저장 중...'
                      : (inquiry.hasAnswer ? '답변 수정' : '답변 등록하고 알림 보내기'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 담당자 표시와 지정.
///
/// "나에게 배정"만 있습니다. 관리자 목록 조회가 최고관리자 전용이라 일반
/// 관리자는 다른 사람을 고를 수 없고, 실무 기본 동작도 "내가 잡는다"입니다.
/// 다른 사람이 잡은 문의에는 넘겨받기로 이름이 바뀝니다.
class _AssigneeControl extends StatelessWidget {
  const _AssigneeControl({required this.inquiry});

  final InquiryDetail inquiry;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<InquiryDetailViewModel>();
    final myEmail = context.watch<AdminSession>().admin?.email;
    final assignee = inquiry.assigneeEmail;
    final isMine = assignee != null && assignee == myEmail;

    Future<void> run(Future<bool> Function() action, String done) async {
      final ok = await action();
      if (!context.mounted) return;
      showResultSnackBar(
        context,
        success: ok,
        message: ok ? done : (vm.errorMessage ?? '처리하지 못했습니다.'),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (assignee == null)
          Text('담당자 없음', style: AppTypography.caption)
        else
          AppStatusChip(
            label: isMine ? '내가 담당' : '담당 $assignee',
            tone: isMine ? StatusTone.info : StatusTone.neutral,
          ),
        const SizedBox(width: AppSpacing.sm),
        if (isMine)
          TextButton(
            onPressed: vm.isBusy
                ? null
                : () => run(vm.unassign, '담당을 해제했습니다.'),
            child: const Text('담당 해제'),
          )
        else
          OutlinedButton(
            onPressed: vm.isBusy
                ? null
                : () => run(
                      vm.assignToMe,
                      assignee == null ? '이 문의를 담당합니다.' : '문의를 넘겨받았습니다.',
                    ),
            child: Text(assignee == null ? '내가 담당하기' : '넘겨받기'),
          ),
      ],
    );
  }
}

/// 자주 쓰는 답변 고르기.
///
/// 고르면 자리표시자를 이 문의에 맞게 채워서 답변 칸에 넣습니다. 이미 쓰던
/// 내용이 있으면 덮어쓰기 전에 물어봅니다.
class _TemplatePicker extends StatelessWidget {
  const _TemplatePicker({
    required this.inquiry,
    required this.templates,
    required this.controller,
  });

  final InquiryDetail inquiry;
  final List<ReplyTemplate> templates;
  final TextEditingController controller;

  Future<void> _apply(BuildContext context, ReplyTemplate template) async {
    if (controller.text.trim().isNotEmpty) {
      final ok = await showConfirmDialog(
        context,
        title: '작성 중인 내용을 바꿀까요?',
        message: '답변 칸에 쓰던 내용이 템플릿으로 바뀝니다.',
        confirmLabel: '바꾸기',
      );
      if (!ok) return;
    }
    controller.text = template.renderFor(inquiry);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (templates.isNotEmpty)
          PopupMenuButton<ReplyTemplate>(
            tooltip: '자주 쓰는 답변',
            onSelected: (template) => _apply(context, template),
            itemBuilder: (context) => [
              for (final template in templates)
                PopupMenuItem(
                  value: template,
                  child: Text(template.title, style: AppTypography.body),
                ),
            ],
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '자주 쓰는 답변',
                    style: AppTypography.body.copyWith(color: AppColors.primary),
                  ),
                  const Icon(
                    Icons.arrow_drop_down_rounded,
                    color: AppColors.primary,
                  ),
                ],
              ),
            ),
          ),
        TextButton(
          onPressed: () => _TemplateManagerDialog.show(context),
          child: const Text('템플릿 관리'),
        ),
      ],
    );
  }
}

/// 템플릿 만들기/고치기/지우기.
class _TemplateManagerDialog extends StatefulWidget {
  const _TemplateManagerDialog({required this.viewModel});

  final InquiryDetailViewModel viewModel;

  static Future<void> show(BuildContext context) {
    final vm = context.read<InquiryDetailViewModel>();
    return showDialog<void>(
      context: context,
      builder: (_) => ChangeNotifierProvider.value(
        value: vm,
        child: _TemplateManagerDialog(viewModel: vm),
      ),
    );
  }

  @override
  State<_TemplateManagerDialog> createState() => _TemplateManagerDialogState();
}

class _TemplateManagerDialogState extends State<_TemplateManagerDialog> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();

  /// 고치는 중인 템플릿. null 이면 새로 만드는 중입니다.
  String? _editingId;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  void _startEdit(ReplyTemplate template) {
    setState(() {
      _editingId = template.id;
      _titleController.text = template.title;
      _bodyController.text = template.body;
    });
  }

  void _reset() {
    setState(() {
      _editingId = null;
      _titleController.clear();
      _bodyController.clear();
    });
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    final body = _bodyController.text;
    if (title.isEmpty || body.trim().isEmpty) {
      showResultSnackBar(context, success: false, message: '이름과 본문을 채워 주세요.');
      return;
    }
    final ok = await widget.viewModel
        .saveTemplate(id: _editingId, title: title, body: body);
    if (!mounted) return;
    if (ok) _reset();
    showResultSnackBar(
      context,
      success: ok,
      message: ok ? '저장했습니다.' : (widget.viewModel.errorMessage ?? '저장하지 못했습니다.'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<InquiryDetailViewModel>();

    return AlertDialog(
      title: const Text('자주 쓰는 답변 관리'),
      content: SizedBox(
        width: 560,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '본문에 {보호자}, {문의제목} 을 쓰면 문의에 맞게 바뀌어 들어갑니다.',
              style: AppTypography.caption,
            ),
            const SizedBox(height: AppSpacing.md),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final template in vm.templates)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        title: Text(template.title, style: AppTypography.body),
                        subtitle: Text(
                          template.body,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.caption,
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextButton(
                              onPressed: () => _startEdit(template),
                              child: const Text('수정'),
                            ),
                            TextButton(
                              onPressed: vm.isBusy
                                  ? null
                                  : () async {
                                      final ok = await showConfirmDialog(
                                        context,
                                        title: '템플릿을 지울까요?',
                                        message:
                                            '"${template.title}" 을(를) 지웁니다. 이미 등록된 답변에는 영향이 없습니다.',
                                        confirmLabel: '지우기',
                                      );
                                      if (!ok) return;
                                      await vm.deleteTemplate(template.id);
                                    },
                              child: const Text('지우기'),
                            ),
                          ],
                        ),
                      ),
                    if (vm.templates.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.md,
                        ),
                        child: Text(
                          '아직 템플릿이 없습니다. 아래에서 첫 템플릿을 만들어 보세요.',
                          style: AppTypography.caption,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const Divider(height: AppSpacing.xl),
            AppField(
              label: _editingId == null ? '새 템플릿 이름' : '템플릿 이름',
              child: TextField(
                controller: _titleController,
                decoration: const InputDecoration(hintText: '예: 환불 안내'),
              ),
            ),
            AppField(
              label: '본문',
              child: TextField(
                controller: _bodyController,
                minLines: 4,
                maxLines: 8,
                decoration: const InputDecoration(
                  hintText: '{보호자} 님, 문의 주셔서 감사합니다.',
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        if (_editingId != null)
          TextButton(onPressed: _reset, child: const Text('새로 만들기로 전환')),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('닫기'),
        ),
        FilledButton(
          onPressed: vm.isBusy ? null : _save,
          child: Text(_editingId == null ? '추가' : '수정 저장'),
        ),
      ],
    );
  }
}

/// 내부 메모. 사용자에게 보이지 않는 팀 안의 기록입니다.
class _NotesCard extends StatefulWidget {
  const _NotesCard({required this.notes, required this.busy});

  final List<InquiryNote> notes;
  final bool busy;

  @override
  State<_NotesCard> createState() => _NotesCardState();
}

class _NotesCardState extends State<_NotesCard> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    final body = _controller.text.trim();
    if (body.isEmpty) return;
    final vm = context.read<InquiryDetailViewModel>();
    final ok = await vm.addNote(body);
    if (!mounted) return;
    if (ok) _controller.clear();
    showResultSnackBar(
      context,
      success: ok,
      message: ok ? '메모를 남겼습니다.' : (vm.errorMessage ?? '남기지 못했습니다.'),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      title: '내부 메모 (${widget.notes.length})',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '사용자에게 보이지 않습니다. 처리 맥락을 남기는 기록이라 수정과 삭제가 없습니다.',
            style: AppTypography.caption,
          ),
          const SizedBox(height: AppSpacing.md),
          for (final note in widget.notes)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(note.authorEmail, style: AppTypography.bodyStrong),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          Formats.dateTime(note.createdAt),
                          style: AppTypography.caption,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    SelectableText(note.body, style: AppTypography.body),
                  ],
                ),
              ),
            ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  minLines: 1,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText: '예: 보호자께 전화드리기로 함',
                  ),
                  onSubmitted: (_) => _add(),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              FilledButton.tonal(
                onPressed: widget.busy ? null : _add,
                child: const Text('메모 남기기'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

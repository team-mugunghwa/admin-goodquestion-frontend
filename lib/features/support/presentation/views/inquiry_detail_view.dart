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
    required this.controller,
    required this.editing,
    required this.busy,
    required this.onEdit,
    required this.onCancelEdit,
    required this.onSubmit,
  });

  final InquiryDetail inquiry;
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

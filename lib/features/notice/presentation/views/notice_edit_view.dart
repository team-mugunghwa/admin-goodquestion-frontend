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

/// 공지 작성·수정. [noticeId] 가 null 이면 새 글입니다.
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

  /// 서버에서 받아온 값을 폼에 한 번만 채웁니다. 매 build 마다 채우면
  /// 타이핑하는 족족 되돌아갑니다.
  bool _filled = false;

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

    if (!_filled && vm.notice != null) {
      _titleController.text = vm.notice!.title;
      _contentController.text = vm.notice!.content;
      _filled = true;
    }

    return AppPage(
      title: vm.isNew ? '공지 작성' : '공지 수정',
      backRoute: AppRoutes.notices,
      description: vm.notice == null
          ? null
          : '조회 ${Formats.count(vm.notice!.viewCount)}회 · '
                '마지막 수정 ${Formats.dateTime(vm.notice!.updatedAt)}',
      actions: [
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

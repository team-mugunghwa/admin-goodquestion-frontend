import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formats.dart';
import '../../../../core/widgets/app_dialogs.dart';
import '../../../../core/widgets/app_form.dart';
import '../../../../core/widgets/app_page.dart';
import '../../domain/entities/db_schema.dart';
import '../viewmodels/table_detail_view_model.dart';

/// 실제 저장된 값.
///
/// 열이 스무 개 넘는 테이블이 있어서 가로 스크롤이 필수입니다. 화면 폭에 맞춰
/// 열을 줄이면 정작 보려던 컬럼이 잘립니다.
class RowGrid extends StatelessWidget {
  const RowGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<TableDetailViewModel>();
    final page = vm.rows;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _FilterBar(columns: page.columns),
        Expanded(
          child: AppCard(
            padding: EdgeInsets.zero,
            child: page.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(AppSpacing.xxl),
                    child: Center(
                      child: Text(
                        vm.keyword.isEmpty
                            ? '저장된 값이 없습니다.'
                            : '검색 결과가 없습니다.',
                        style: AppTypography.caption,
                      ),
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: _Grid(page: page)),
                      _Pagination(page: page),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}

class _FilterBar extends StatefulWidget {
  const _FilterBar({required this.columns});

  final List<DbColumn> columns;

  @override
  State<_FilterBar> createState() => _FilterBarState();
}

class _FilterBarState extends State<_FilterBar> {
  String? _column;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<TableDetailViewModel>();
    // 가려진 컬럼으로는 검색해도 값을 볼 수 없으니 후보에서 뺍니다.
    final searchable = widget.columns.where((c) => !c.masked).toList();
    _column ??= searchable.isEmpty ? null : searchable.first.name;

    return AppFilterBar(
      children: [
        SizedBox(
          width: 200,
          child: DropdownButtonFormField<String>(
            initialValue: _column,
            isExpanded: true,
            style: AppTypography.body,
            items: [
              for (final column in searchable)
                DropdownMenuItem(
                  value: column.name,
                  child: Text(column.name, overflow: TextOverflow.ellipsis),
                ),
            ],
            onChanged: (value) => setState(() => _column = value),
          ),
        ),
        AppSearchField(
          width: 320,
          hintText: '값으로 검색 (부분 일치)',
          initialValue: vm.keyword,
          onSubmitted: (value) => context.read<TableDetailViewModel>().search(
            column: _column,
            keyword: value,
          ),
        ),
        Text(
          '${Formats.count(vm.rows.totalElements)}행',
          style: AppTypography.caption,
        ),
        if (vm.isBusy)
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
      ],
    );
  }
}

class _Grid extends StatelessWidget {
  const _Grid({required this.page});

  final DbRowPage page;

  /// 열 하나의 폭. 값이 길어도 표가 무너지지 않게 고정합니다.
  static const double _columnWidth = 200;

  @override
  Widget build(BuildContext context) {
    final vm = context.read<TableDetailViewModel>();

    return Scrollbar(
      thumbVisibility: true,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: page.columns.length * _columnWidth,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _HeaderRow(columns: page.columns, viewModel: vm),
              Expanded(
                child: ListView.builder(
                  itemCount: page.rows.length,
                  itemBuilder: (context, index) => _DataRow(
                    columns: page.columns,
                    row: page.rows[index],
                    striped: index.isOdd,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow({required this.columns, required this.viewModel});

  final List<DbColumn> columns;
  final TableDetailViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: const BoxDecoration(
        color: AppColors.surfaceMuted,
        border: Border(bottom: BorderSide(color: AppColors.ink100)),
      ),
      child: Row(
        children: [
          for (final column in columns)
            SizedBox(
              width: _Grid._columnWidth,
              // 컬럼 이름만으로는 뜻을 모르므로 설명을 툴팁으로 붙입니다.
              child: Tooltip(
                message: column.comment ?? column.name,
                waitDuration: const Duration(milliseconds: 300),
                child: InkWell(
                  onTap: () => viewModel.sortBy(column.name),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            column.name,
                            style: AppTypography.tableHeader,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (viewModel.sortColumn == column.name)
                          Icon(
                            viewModel.sortDirection == 'asc'
                                ? Icons.arrow_upward_rounded
                                : Icons.arrow_downward_rounded,
                            size: 12,
                            color: AppColors.primary,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DataRow extends StatelessWidget {
  const _DataRow({
    required this.columns,
    required this.row,
    required this.striped,
  });

  final List<DbColumn> columns;
  final Map<String, Object?> row;
  final bool striped;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 40),
      decoration: BoxDecoration(
        // 열이 많아 가로로 길므로 줄무늬가 있어야 같은 행을 눈으로 따라갑니다.
        color: striped ? AppColors.canvas : AppColors.surface,
        border: const Border(bottom: BorderSide(color: AppColors.ink100)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          for (final column in columns)
            SizedBox(
              width: _Grid._columnWidth,
              child: _Cell(column: column, value: row[column.name]),
            ),
        ],
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({required this.column, required this.value});

  final DbColumn column;
  final Object? value;

  @override
  Widget build(BuildContext context) {
    final text = _render(value);
    final isNull = value == null;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: InkWell(
        // 값이 잘리는 경우가 많아 눌러서 전체를 보고 복사할 수 있게 합니다.
        onTap: isNull || column.masked ? null : () => _showValue(context, text),
        child: Text(
          isNull ? 'null' : text,
          style: AppTypography.body.copyWith(
            color: isNull
                ? AppColors.ink400
                : column.masked
                ? AppColors.danger
                : AppColors.ink900,
            fontStyle: isNull ? FontStyle.italic : FontStyle.normal,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  static String _render(Object? value) => switch (value) {
    null => 'null',
    List<Object?> items => items.isEmpty ? '[]' : items.join(', '),
    _ => value.toString(),
  };

  void _showValue(BuildContext context, String text) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(column.name),
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (column.comment != null) ...[
                  Text(column.comment!, style: AppTypography.caption),
                  const SizedBox(height: AppSpacing.md),
                ],
                SelectableText(text, style: AppTypography.body),
              ],
            ),
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        actions: [
          TextButton.icon(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: text));
              if (!context.mounted) return;
              Navigator.of(context).pop();
              showResultSnackBar(context, success: true, message: '복사했습니다.');
            },
            icon: const Icon(Icons.copy_rounded, size: AppSizes.icon),
            label: const Text('복사'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }
}

class _Pagination extends StatelessWidget {
  const _Pagination({required this.page});

  final DbRowPage page;

  @override
  Widget build(BuildContext context) {
    final vm = context.read<TableDetailViewModel>();
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.ink100)),
      ),
      child: Row(
        children: [
          Text(
            '전체 ${Formats.count(page.totalElements)}행 중 '
            '${page.page * page.size + 1}부터 '
            '${page.page * page.size + page.rows.length}까지',
            style: AppTypography.caption,
          ),
          const Spacer(),
          IconButton(
            tooltip: '이전',
            onPressed: page.hasPrevious
                ? () => vm.loadRows(page: page.page - 1)
                : null,
            icon: const Icon(AppIcons.previousPage),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: Text(
              '${page.page + 1} / ${page.totalPages}',
              style: AppTypography.number,
            ),
          ),
          IconButton(
            tooltip: '다음',
            onPressed: page.hasNext ? () => vm.loadRows(page: page.page + 1) : null,
            icon: const Icon(AppIcons.nextPage),
          ),
        ],
      ),
    );
  }
}

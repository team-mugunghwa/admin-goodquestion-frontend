import 'package:flutter/material.dart';

import '../network/page_result.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'app_pagination.dart';

/// 표의 열 정의.
///
/// @param flex 남는 폭을 나눠 갖는 비율. [width] 를 주면 무시됩니다.
/// @param width 고정 폭. 상태 배지나 날짜처럼 내용 길이가 일정한 열에 씁니다.
class AppColumn<T> {
  const AppColumn({
    required this.label,
    required this.cellBuilder,
    this.flex = 1,
    this.width,
    this.alignment = Alignment.centerLeft,
  });

  final String label;
  final Widget Function(BuildContext context, T item) cellBuilder;
  final int flex;
  final double? width;
  final Alignment alignment;
}

/// 목록 표.
///
/// Flutter 의 `DataTable` 을 쓰지 않습니다. 그쪽은 열 폭이 내용에 따라 정해져서
/// 페이지를 넘길 때마다 열 경계가 흔들립니다 - 같은 표를 여러 페이지에 걸쳐 훑는
/// 관리자 화면에서는 그 흔들림이 계속 눈에 걸립니다. 여기서는 [AppColumn.flex] 로
/// 폭을 고정합니다.
class AppDataTable<T> extends StatelessWidget {
  const AppDataTable({
    required this.columns,
    required this.items,
    this.onRowTap,
    this.rowKey,
    super.key,
  });

  final List<AppColumn<T>> columns;
  final List<T> items;

  /// 행 전체를 누를 수 있게 합니다. 상세로 들어가는 표에 씁니다.
  final void Function(T item)? onRowTap;

  /// 행을 구분하는 값. 지정하면 목록이 바뀌어도 스크롤과 상태가 덜 흔들립니다.
  final Object Function(T item)? rowKey;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        _HeaderRow(columns: columns),
        for (final item in items)
          _BodyRow<T>(
            key: rowKey == null ? null : ValueKey(rowKey!(item)),
            columns: columns,
            item: item,
            onTap: onRowTap == null ? null : () => onRowTap!(item),
          ),
      ],
    );
  }
}

class _HeaderRow<T> extends StatelessWidget {
  const _HeaderRow({required this.columns});

  final List<AppColumn<T>> columns;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      decoration: const BoxDecoration(
        color: AppColors.surfaceMuted,
        border: Border(bottom: BorderSide(color: AppColors.ink100)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Row(
        children: [
          for (final column in columns)
            _Cell(
              column: column,
              child: Text(column.label, style: AppTypography.tableHeader),
            ),
        ],
      ),
    );
  }
}

class _BodyRow<T> extends StatefulWidget {
  const _BodyRow({required this.columns, required this.item, this.onTap, super.key});

  final List<AppColumn<T>> columns;
  final T item;
  final VoidCallback? onTap;

  @override
  State<_BodyRow<T>> createState() => _BodyRowState<T>();
}

class _BodyRowState<T> extends State<_BodyRow<T>> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final row = Container(
      constraints: const BoxConstraints(minHeight: AppSizes.tableRowHeight),
      decoration: BoxDecoration(
        color: _hovered && widget.onTap != null
            ? AppColors.surfaceMuted
            : AppColors.surface,
        border: const Border(bottom: BorderSide(color: AppColors.ink100)),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          for (final column in widget.columns)
            _Cell(
              column: column,
              child: DefaultTextStyle.merge(
                style: AppTypography.body,
                child: column.cellBuilder(context, widget.item),
              ),
            ),
        ],
      ),
    );

    if (widget.onTap == null) return row;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(onTap: widget.onTap, child: row),
    );
  }
}

class _Cell<T> extends StatelessWidget {
  const _Cell({required this.column, required this.child});

  final AppColumn<T> column;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final content = Align(
      alignment: column.alignment,
      child: Padding(
        padding: const EdgeInsets.only(right: AppSpacing.md),
        child: child,
      ),
    );
    return column.width != null
        ? SizedBox(width: column.width, child: content)
        : Expanded(flex: column.flex, child: content);
  }
}

/// 표 + 페이지네이션을 한 카드 안에 그립니다. 목록 화면이 거의 항상 쓰는 조합입니다.
class AppPagedTable<T> extends StatelessWidget {
  const AppPagedTable({
    required this.columns,
    required this.result,
    required this.onPageChanged,
    this.onRowTap,
    this.rowKey,
    super.key,
  });

  final List<AppColumn<T>> columns;
  final PageResult<T> result;
  final ValueChanged<int> onPageChanged;
  final void Function(T item)? onRowTap;
  final Object Function(T item)? rowKey;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        AppDataTable<T>(
          columns: columns,
          items: result.content,
          onRowTap: onRowTap,
          rowKey: rowKey,
        ),
        AppPagination(result: result, onPageChanged: onPageChanged),
      ],
    );
  }
}

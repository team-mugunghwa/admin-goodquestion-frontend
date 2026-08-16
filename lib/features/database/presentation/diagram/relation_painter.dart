import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import 'schema_layout.dart';

/// 상자 사이의 선을 그립니다.
///
/// ## 까마귀발 표기
///
/// 선의 양 끝 모양이 "몇 대 몇"을 알려 줍니다. 갈래진 쪽(까마귀발)이 여러 건이
/// 있을 수 있는 쪽이고, 막대 하나로 끝나는 쪽이 하나뿐인 쪽입니다. `children` 에서
/// `parents` 로 가는 선이라면 아이 쪽이 갈래지고 보호자 쪽이 막대입니다. 아이는
/// 여럿이지만 그 아이의 보호자는 하나라는 뜻입니다.
///
/// 막대 옆에 동그라미가 붙으면 없을 수도 있는 관계입니다. 참조하는 컬럼이 비어
/// 있어도 되는 경우입니다.
class RelationPainter extends CustomPainter {
  const RelationPainter({required this.relations, this.focusedTable});

  final List<PlacedRelation> relations;
  final String? focusedTable;

  /// 곡선이 상자에서 빠져나가는 거리. 짧으면 선이 상자에 붙어 꺾입니다.
  static const double _curve = 64;
  static const double _footLength = 13;
  static const double _footSpread = 7;

  @override
  void paint(Canvas canvas, Size size) {
    // 흐린 선을 먼저 그려야 진한 선이 그 위에 옵니다.
    final ordered = [
      ...relations.where((relation) => !_isFocused(relation)),
      ...relations.where(_isFocused),
    ];
    for (final relation in ordered) {
      _paintRelation(canvas, relation, _isFocused(relation));
    }
  }

  bool _isFocused(PlacedRelation relation) =>
      focusedTable != null && relation.relation.touches(focusedTable!);

  void _paintRelation(Canvas canvas, PlacedRelation placed, bool focused) {
    final dim = focusedTable != null && !focused;
    final color = focused
        ? AppColors.primary
        : dim
        ? AppColors.ink100
        : AppColors.ink300;

    final paint = Paint()
      ..color = color
      ..strokeWidth = focused ? 1.8 : 1.2
      ..style = PaintingStyle.stroke;

    final startDirection = placed.startsOnLeft ? -1.0 : 1.0;
    final endDirection = placed.endsOnLeft ? -1.0 : 1.0;

    canvas.drawPath(
      Path()
        ..moveTo(placed.start.dx, placed.start.dy)
        ..cubicTo(
          placed.start.dx + _curve * startDirection,
          placed.start.dy,
          placed.end.dx + _curve * endDirection,
          placed.end.dy,
          placed.end.dx,
          placed.end.dy,
        ),
      paint,
    );

    _paintCrowsFoot(canvas, placed.start, startDirection, paint);
    _paintOneEnd(
      canvas,
      placed.end,
      endDirection,
      paint,
      optional: placed.relation.optional,
    );
  }

  /// 여러 건이 있을 수 있는 쪽. 상자 면에서 세 갈래로 벌어집니다.
  void _paintCrowsFoot(
    Canvas canvas,
    Offset edge,
    double direction,
    Paint paint,
  ) {
    final base = Offset(edge.dx + _footLength * direction, edge.dy);
    canvas
      ..drawLine(base, edge, paint)
      ..drawLine(base, Offset(edge.dx, edge.dy - _footSpread), paint)
      ..drawLine(base, Offset(edge.dx, edge.dy + _footSpread), paint);
  }

  /// 하나뿐인 쪽. 막대 하나, 없을 수도 있으면 동그라미를 하나 더 붙입니다.
  void _paintOneEnd(
    Canvas canvas,
    Offset edge,
    double direction,
    Paint paint, {
    required bool optional,
  }) {
    final barX = edge.dx + 11 * direction;
    canvas.drawLine(
      Offset(barX, edge.dy - _footSpread),
      Offset(barX, edge.dy + _footSpread),
      paint,
    );
    if (!optional) return;

    canvas.drawCircle(
      Offset(edge.dx + 20 * direction, edge.dy),
      3.5,
      Paint()
        ..color = paint.color
        ..strokeWidth = paint.strokeWidth
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(RelationPainter oldDelegate) =>
      oldDelegate.relations != relations ||
      oldDelegate.focusedTable != focusedTable;
}

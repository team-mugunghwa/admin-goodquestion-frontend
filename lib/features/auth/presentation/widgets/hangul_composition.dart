import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// 한글 자음이 한 획씩 그려지는 모습을 반복해서 보여 줍니다.
///
/// ## 왜 이걸 두나
///
/// 로그인 화면 왼쪽 윗자리입니다. 로고를 그대로 놓는 대신, 이 서비스가 다루는
/// 것을 보여 주려는 것입니다. 아이가 처음 배우는 자음이 순서대로 그려집니다.
///
/// ## 글자를 쓰지 않고 직접 그리는 이유
///
/// 낱자(ㄱ, ㄴ 같은 호환용 자모)는 글꼴에 따라 빠져 있는 경우가 있습니다. 실제로
/// 브라우저에서 네모로 나오는 것을 봤습니다. 획을 좌표로 들고 직접 그리면 어떤
/// 환경에서도 같은 모양이 나옵니다. 삽화 파일을 쓰지 않는 이유는 또 있습니다 -
/// 그림을 넣으면 오른쪽 문장과 시선을 나눠 갖습니다.
class HangulComposition extends StatefulWidget {
  const HangulComposition({super.key});

  static const Duration cycle = Duration(milliseconds: 2600);

  @override
  State<HangulComposition> createState() => _HangulCompositionState();
}

class _HangulCompositionState extends State<HangulComposition>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: HangulComposition.cycle,
  );

  int _index = 0;

  @override
  void initState() {
    super.initState();
    _controller
      ..addStatusListener(_onCycleEnd)
      ..forward();
  }

  void _onCycleEnd(AnimationStatus status) {
    if (status != AnimationStatus.completed || !mounted) return;
    setState(() => _index = (_index + 1) % _Jamo.all.length);
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final jamo = _Jamo.all[_index];

    // 움직임을 줄여 달라고 설정한 사용자에게는 다 그려진 모습만 보여 줍니다.
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return SizedBox(
      width: _JamoPainter.canvas,
      height: _JamoPainter.canvas,
      child: reduceMotion
          ? CustomPaint(painter: _JamoPainter(jamo: jamo, drawn: 1, opacity: 1))
          : AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final t = _controller.value;
                return CustomPaint(
                  painter: _JamoPainter(
                    jamo: jamo,
                    // 0.00-0.55 그리는 중, 0.55-0.85 유지, 0.85-1.00 사라짐
                    drawn: Curves.easeInOut.transform(
                      (t / 0.55).clamp(0.0, 1.0),
                    ),
                    opacity: 1 - ((t - 0.85) / 0.15).clamp(0.0, 1.0),
                  ),
                );
              },
            ),
    );
  }
}

/// 자음 하나의 획. 좌표는 100x100 기준이고 그릴 때 실제 크기로 늘립니다.
///
/// 획을 나눠 둔 것은 쓰는 순서를 지키기 위해서입니다. ㅅ 처럼 두 획인 글자는
/// 왼쪽 삐침을 먼저 긋습니다.
class _Jamo {
  const _Jamo(this.name, this.strokes);

  final String name;
  final List<List<Offset>> strokes;

  /// 자음 순서 그대로 넷. "가나다라" 를 배우는 순서라서 무엇을 보여 주는지가
  /// 설명 없이 읽힙니다. 미음(네모)은 뺐습니다 - 글자가 깨져 나온 빈 네모로
  /// 오해하기 쉽습니다.
  static const List<_Jamo> all = [
    _Jamo('기역', [
      [Offset(18, 22), Offset(82, 22), Offset(70, 82)],
    ]),
    _Jamo('니은', [
      [Offset(24, 18), Offset(24, 78), Offset(84, 78)],
    ]),
    _Jamo('디귿', [
      [Offset(80, 20), Offset(22, 20), Offset(22, 78), Offset(80, 78)],
    ]),
    _Jamo('리을', [
      [
        Offset(22, 20),
        Offset(78, 20),
        Offset(78, 46),
        Offset(22, 46),
        Offset(22, 74),
        Offset(78, 74),
      ],
    ]),
  ];
}

class _JamoPainter extends CustomPainter {
  const _JamoPainter({
    required this.jamo,
    required this.drawn,
    required this.opacity,
  });

  final _Jamo jamo;

  /// 획을 얼마나 그렸는지. 0이면 아무것도 없고 1이면 다 그려집니다.
  final double drawn;

  final double opacity;

  static const double canvas = 84;
  static const double _reference = 100;

  @override
  void paint(Canvas canvas, Size size) {
    if (opacity <= 0) return;

    final scale = size.width / _reference;
    final paint = Paint()
      ..color = AppColors.primary.withValues(alpha: opacity)
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    // 획 전체를 하나의 길이로 보고 앞에서부터 잘라 그립니다. 그래야 획이 여럿일
    // 때도 순서대로 이어서 그려집니다.
    final path = Path();
    for (final stroke in jamo.strokes) {
      path.moveTo(stroke.first.dx * scale, stroke.first.dy * scale);
      for (final point in stroke.skip(1)) {
        path.lineTo(point.dx * scale, point.dy * scale);
      }
    }

    final metrics = path.computeMetrics().toList();
    final total = metrics.fold<double>(0, (sum, m) => sum + m.length);
    var remaining = total * drawn;

    for (final metric in metrics) {
      if (remaining <= 0) break;
      final take = remaining < metric.length ? remaining : metric.length;
      canvas.drawPath(metric.extractPath(0, take), paint);
      remaining -= take;
    }
  }

  @override
  bool shouldRepaint(_JamoPainter oldDelegate) =>
      oldDelegate.drawn != drawn ||
      oldDelegate.opacity != opacity ||
      oldDelegate.jamo != jamo;
}

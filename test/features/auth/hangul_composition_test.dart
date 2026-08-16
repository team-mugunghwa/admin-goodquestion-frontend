import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goodquestion_admin/features/auth/presentation/widgets/hangul_composition.dart';

/// 로그인 화면의 자음 애니메이션.
///
/// 글자가 아니라 좌표를 들고 직접 그립니다. 낱자 글꼴이 없는 환경에서 빈 네모로
/// 나오는 것을 실제로 봤기 때문입니다. 그래서 "글꼴 없이도 그려지는가"와
/// "계속 돌아가는가" 를 확인합니다.
void main() {
  Future<void> pumpAnimation(WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Center(child: HangulComposition())),
      ),
    );
  }

  testWidgets('글자 위젯 없이 직접 그린다', (tester) async {
    await pumpAnimation(tester);

    // Text 를 쓰면 낱자 글꼴이 없는 환경에서 빈 네모가 나옵니다.
    expect(find.byType(Text), findsNothing);
    expect(find.byType(CustomPaint), findsWidgets);

    await tester.pump(const Duration(milliseconds: 700));
  });

  testWidgets('한 자음이 끝나면 다음 자음으로 넘어간다', (tester) async {
    await pumpAnimation(tester);

    CustomPainter painterNow() => tester
        .widgetList<CustomPaint>(find.byType(CustomPaint))
        .map((paint) => paint.painter)
        .whereType<CustomPainter>()
        .last;

    await tester.pump(const Duration(milliseconds: 800));
    final first = painterNow();

    // 한 주기를 넘긴 뒤에는 다른 자음을 그리고 있어야 합니다.
    await tester.pump(HangulComposition.cycle);
    await tester.pump(const Duration(milliseconds: 800));
    final second = painterNow();

    expect(first.shouldRepaint(second), isTrue);
  });

  testWidgets('움직임을 줄이는 설정이면 완성된 모양만 보여 준다', (tester) async {
    await tester.pumpWidget(
      const MediaQuery(
        data: MediaQueryData(disableAnimations: true),
        child: MaterialApp(
          home: Scaffold(body: Center(child: HangulComposition())),
        ),
      ),
    );

    // 애니메이션이 돌지 않아도 화면이 비지 않아야 합니다.
    expect(find.byType(CustomPaint), findsWidgets);
    await tester.pump(const Duration(seconds: 1));
    expect(tester.takeException(), isNull);
  });
}

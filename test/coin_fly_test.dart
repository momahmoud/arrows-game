import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:arrow_escape/ui/widgets/coin_fly.dart';
import 'package:arrow_escape/ui/widgets/game_button.dart';

void main() {
  testWidgets('every flying coin pops the balance it lands on', (tester) async {
    final fromKey = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              const Positioned(
                top: 40,
                right: 20,
                child: CoinAnchor(child: SizedBox(width: 80, height: 30)),
              ),
              Positioned(
                bottom: 60,
                left: 100,
                child: SizedBox(key: fromKey, width: 40, height: 40),
              ),
            ],
          ),
        ),
      ),
    );
    final context = tester.element(find.byType(Scaffold));
    final from = CoinFly.of(fromKey.currentContext!)!;
    CoinFly.burst(context, from: from, count: 5);

    double scaleNow() => tester
        .widget<Transform>(
          find
              .descendant(
                of: find.byType(CoinAnchor),
                matching: find.byType(Transform),
              )
              .first,
        )
        .transform
        .storage[0];

    await tester.pump();
    expect(scaleNow(), 1.0, reason: 'nothing has landed yet');

    var popped = false;
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 25));
      if (scaleNow() > 1.0) popped = true;
    }
    expect(popped, isTrue);
    await tester.pump(const Duration(seconds: 2));
    expect(scaleNow(), 1.0);
  });
}

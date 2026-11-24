import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:panel_puzzle/shared/sprite_demo.dart';
import 'package:panel_puzzle/sprite/sprite.dart';

void main() {
  testWidgets('waits for the atlas before building sprites', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SpriteDemo()));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.runAsync(() async {
      for (var i = 0; i < 100; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
        await tester.pump();
        if (find.byType(CircularProgressIndicator).evaluate().isEmpty) break;
      }
    });

    expect(find.textContaining('Error loading sprite:'), findsNothing);
    expect(find.byType(AnimatedSprite), findsNWidgets(16));
    expect(find.byType(Sprite), findsNWidgets(16));
    expect(tester.takeException(), isNull);

    final controller = tester.widget<AnimatedSprite>(
      find.byType(AnimatedSprite).first,
    ).controller;
    expect(controller.currentFrame, 'kirb groove0000');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(controller.currentFrame, 'kirb groove0002');

    await tester.pump(const Duration(seconds: 2));
    await tester.tap(find.byType(AnimatedSprite).first);
    await tester.pump();
    expect(controller.currentFrame, 'kirb hurt0000');
    await tester.pump(const Duration(milliseconds: 50));
    expect(controller.currentFrame, 'kirb hurt0001');
    await tester.pump(const Duration(milliseconds: 350));
    expect(controller.currentFrame, 'kirb hurt0000');

    await tester.tap(find.byType(AnimatedSprite).first);
    await tester.pump();
    expect(controller.currentFrame, 'kirb victory0000');
    expect(tester.takeException(), isNull);
  });
}

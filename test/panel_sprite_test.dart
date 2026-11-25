import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:panel_puzzle/game/panel.dart';
import 'package:panel_puzzle/sprite/sprite.dart';
import 'package:panel_puzzle/sprite/sprite_frame.dart';

void main() {
  test('frame names retain digits in a four-digit-suffixed prefix', () {
    const frame = SpriteFrame(
      textureName: 'panel_flip_10011',
      srcRect: Rect.zero,
      trimOffset: Offset.zero,
      originalSize: Size.zero,
    );
    expect(frame.frameName, 'panel_flip_1');
    expect(frame.frameNumber, 11);
  });

  testWidgets('loads the panel atlas and plays flips and victory', (tester) async {
    var victoryCompletions = 0;
    Widget panel({required bool flipped, bool victory = false}) => MaterialApp(
      home: Center(
        child: Panel(
          isFlipped: flipped,
          isVictory: victory,
          onVictoryComplete: () => victoryCompletions++,
        ),
      ),
    );

    await tester.pumpWidget(panel(flipped: false));
    await tester.runAsync(() async {
      for (var i = 0; i < 150 && find.byType(AnimatedSprite).evaluate().isEmpty; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
        await tester.pump();
      }
    });

    expect(find.textContaining('Error loading sprite:'), findsNothing);
    expect(find.byType(AnimatedSprite), findsOneWidget);
    final controller = tester.widget<AnimatedSprite>(find.byType(AnimatedSprite)).controller;
    expect(controller.atlas.frameCollection.getFramesByPrefix(prefix: 'panel_flip_1').length, 12);
    expect(controller.atlas.frameCollection.getFramesByPrefix(prefix: 'panel_flip_2').length, 12);
    expect(controller.currentFrame, 'panel_flip_20011');

    await tester.pumpWidget(panel(flipped: true));
    expect(controller.currentFrame, 'panel_flip_10000');
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(controller.currentFrame, 'panel_flip_10011');

    await tester.pumpWidget(panel(flipped: false));
    expect(controller.currentFrame, 'panel_flip_20000');
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(controller.currentFrame, 'panel_flip_20011');

    await tester.pumpWidget(panel(flipped: false, victory: true));
    expect(controller.currentFrame, 'clear panel0000');
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(controller.currentFrame, 'clear panel0012');
    expect(victoryCompletions, 1);
    expect(tester.takeException(), isNull);
  });
}

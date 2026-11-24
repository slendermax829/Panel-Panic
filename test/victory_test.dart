import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:panel_puzzle/game/board.dart';
import 'package:panel_puzzle/game/game_set.dart';
import 'package:panel_puzzle/game/panel.dart';
import 'package:panel_puzzle/sprite/sprite.dart';

void main() {
  testWidgets('plays the player board victory before showing the clear dialog', (tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(appBarTheme: const AppBarTheme(
        toolbarTextStyle: TextStyle(fontSize: 12),
      )),
      home: const GameSet(),
    ));
    await tester.runAsync(() async {
      for (var i = 0; i < 150; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
        await tester.pump();
        if (find.byType(AnimatedSprite).evaluate().length == 32) break;
      }
    });
    expect(find.byType(AnimatedSprite), findsNWidgets(32));

    final boards = find.byType(Board);
    final targetPanels = find.descendant(of: boards.first, matching: find.byType(Panel));
    final playerPanels = find.descendant(of: boards.last, matching: find.byType(Panel));
    List<bool> states(Finder finder) =>
        tester.widgetList<Panel>(finder).map((panel) => panel.isFlipped).toList();
    final target = states(targetPanels);
    final player = states(playerPanels);

    List<bool> flip(List<bool> board, int index) {
      final result = List<bool>.of(board);
      for (var i = 0; i < result.length; i++) {
        if (((i ~/ GameSet.gridSize) - (index ~/ GameSet.gridSize)).abs() <= 1 &&
            ((i % GameSet.gridSize) - (index % GameSet.gridSize)).abs() <= 1) {
          result[i] = !result[i];
        }
      }
      return result;
    }

    bool matches(List<bool> first, List<bool> second) {
      for (var i = 0; i < first.length; i++) {
        if (first[i] != second[i]) return false;
      }
      return true;
    }

    List<int>? solution;
    for (var first = 0; first < player.length && solution == null; first++) {
      final once = flip(player, first);
      if (matches(once, target)) {
        solution = [first];
        break;
      }
      for (var second = 0; second < player.length; second++) {
        if (matches(flip(once, second), target)) {
          solution = [first, second];
          break;
        }
      }
    }
    expect(solution, isNotNull);
    for (final index in solution!) {
      await tester.tap(playerPanels.at(index));
      await tester.pump();
    }

    final playerSprites = find.descendant(of: boards.last, matching: find.byType(AnimatedSprite));
    final targetSprites = find.descendant(of: boards.first, matching: find.byType(AnimatedSprite));
    for (final sprite in tester.widgetList<AnimatedSprite>(playerSprites)) {
      expect(sprite.controller.currentFrame, 'kirb victory0000');
    }
    for (final sprite in tester.widgetList<AnimatedSprite>(targetSprites)) {
      expect(sprite.controller.currentFrame, isNot(startsWith('kirb victory')));
    }
    expect(find.text('Congratulations!'), findsNothing);
    final controller = tester.widget<AnimatedSprite>(playerSprites.first).controller;
    final frames = controller.atlas.frameCollection.getFramesByPrefix(prefix: 'kirb victory');
    final duration = Duration(microseconds: frames.length * (1000000 / 24).round());
    await tester.pump();
    await tester.pump(duration - const Duration(microseconds: 1));
    expect(find.text('Congratulations!'), findsNothing);
    await tester.pump(const Duration(microseconds: 1));
    await tester.pumpAndSettle();
    expect(find.text('Congratulations!'), findsOneWidget);
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Congratulations!'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:panel_puzzle/game/board.dart';
import 'package:panel_puzzle/game/game_set.dart';
import 'package:panel_puzzle/game/panel.dart';
import 'package:panel_puzzle/sprite/sprite.dart';

void main() {
  for (final tappedIndex in [0, 5]) {
    testWidgets('flips the tapped panel and neighbors at index $tappedIndex',
        (tester) async {
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
      final originalTarget = states(targetPanels);
      final original = states(playerPanels);

      await tester.tap(playerPanels.at(tappedIndex));
      await tester.pump();
      final updated = states(playerPanels);
      final sprites = find.descendant(
        of: boards.last,
        matching: find.byType(AnimatedSprite),
      );
      final tappedRow = tappedIndex ~/ GameSet.gridSize;
      final tappedColumn = tappedIndex % GameSet.gridSize;
      for (var i = 0; i < original.length; i++) {
        final affected = ((i ~/ GameSet.gridSize) - tappedRow).abs() <= 1 &&
            ((i % GameSet.gridSize) - tappedColumn).abs() <= 1;
        expect(updated[i], affected ? !original[i] : original[i], reason: 'panel $i');
        if (affected) {
          final sprite = tester.widget<AnimatedSprite>(sprites.at(i));
          final prefix = updated[i] ? 'kirb groove' : 'kirb hurt';
          expect(sprite.controller.currentFrame, '${prefix}0000', reason: 'panel $i');
        }
      }
      expect(states(targetPanels), originalTarget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:panel_puzzle/game/game_set.dart';
import 'package:panel_puzzle/game/titleScreen.dart';
import 'package:panel_puzzle/main.dart';
import 'package:panel_puzzle/shared/GameTransition.dart';

void main() {
  testWidgets('title and menu cards are visible, separate, and tappable', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MyApp());

    final title = tester.getRect(find.text('Panel Panic'));
    final cards = find.byType(Card);
    expect(cards, findsNWidgets(3));
    var previousBottom = title.bottom;
    for (var i = 0; i < 3; i++) {
      final rect = tester.getRect(cards.at(i));
      expect(rect.top, greaterThan(previousBottom));
      expect(rect.height, greaterThanOrEqualTo(80));
      expect(rect.width, greaterThan(0));
      previousBottom = rect.bottom;
    }
    for (final label in ['Random Game', 'Custom Game', 'Create Custom Board']) {
      expect(find.text(label), findsOneWidget);
    }
    await tester.tap(find.text('Custom Game'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('menu remains accessible on a short screen', (tester) async {
    tester.view.physicalSize = const Size(320, 240);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MyApp());
    await tester.ensureVisible(find.text('Create Custom Board'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create Custom Board'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('random game opens at the pulse midpoint and can return', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MyApp());
    final position = tester.getCenter(find.text('Random Game'));
    await tester.tapAt(position);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
    final clip = tester.widget<ClipPath>(
      find.byWidgetPredicate((widget) =>
          widget is ClipPath && widget.clipper is CircleRevealClipper),
    );
    final clipper = clip.clipper! as CircleRevealClipper;
    expect(clipper.center, position);
    expect(clipper.fraction, greaterThan(0));
    expect(clipper.fraction, lessThan(1));
    expect(find.byType(GameSet), findsNothing);
    await tester.pump(const Duration(milliseconds: 799));
    expect(find.byType(GameSet), findsNothing);
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump();
    expect(find.byType(GameSet), findsOneWidget);
    expect(tester.widget<GameSet>(find.byType(GameSet)).mode, Mode.Random);
    final midpointClip = tester.widget<ClipPath>(
      find.byWidgetPredicate((widget) =>
          widget is ClipPath && widget.clipper is CircleRevealClipper),
    );
    expect((midpointClip.clipper! as CircleRevealClipper).fraction, 1);
    await tester.pump(const Duration(milliseconds: 1600));
    expect(find.text('Random Game'), findsOneWidget);
    await tester.pageBack();
    await tester.pump();
    expect(find.byType(Titlescreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

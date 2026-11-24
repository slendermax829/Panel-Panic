import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:panel_puzzle/main.dart';
import 'package:panel_puzzle/shared/background.dart';

void main() {
  testWidgets('keeps the background behind navigable routes', (tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MyApp());
    await tester.pump();

    expect(find.byType(Background), findsOneWidget);
    expect(find.text('Random Game'), findsOneWidget);
    final backgroundContext = tester.element(find.byType(Background));
    await tester.runAsync(() async {
      await precacheImage(const AssetImage('assets/images/background.png'), backgroundContext);
      await precacheImage(const AssetImage('assets/images/pillar.png'), backgroundContext);
    });
    await tester.pump();
    expect(tester.takeException(), isNull);

    final images = find.descendant(
      of: find.byType(Background),
      matching: find.byType(Image),
    );
    expect(images, findsNWidgets(3));
    for (var i = 0; i < 3; i++) {
      expect(tester.getSize(images.at(i)).height, greaterThan(0));
    }

    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    navigator.push(MaterialPageRoute<void>(
      builder: (context) => Scaffold(
        body: Center(
          child: TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Back'),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.byType(Background), findsOneWidget);
    expect(find.text('Back'), findsOneWidget);

    await tester.tap(find.text('Back'));
    await tester.pumpAndSettle();
    expect(find.text('Random Game'), findsOneWidget);
    expect(find.byType(Background), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

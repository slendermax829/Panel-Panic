import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:panel_puzzle/main.dart';
import 'package:panel_puzzle/sprite/sprite.dart';
import 'package:panel_puzzle/sprite/sprite_animation.dart';
import 'package:panel_puzzle/sprite/sprite_frame.dart';
import 'dart:io';

import 'package:xml/xml.dart';

const String testSpriteName = 'Kirb Groove';

void main(){
  TestWidgetsFlutterBinding.ensureInitialized();
  
  group('tester to see if program can read sprite image/xml sheet', (){
    testWidgets('plays sprite frames at the configured fps', (tester) async {
      await tester.runAsync(() async {
        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: SpriteWidget(name: testSpriteName, fps: 24),
          ),
        );
        for (var i = 0; i < 100; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 20));
          await tester.pump();
          if (find.byType(CircularProgressIndicator).evaluate().isEmpty) {
            break;
          }
        }
      });

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.textContaining('Error:'), findsNothing);

      String currentFrameName() {
        final paint = tester.widget<CustomPaint>(
          find.descendant(
            of: find.byType(SpriteWidget),
            matching: find.byWidgetPredicate(
              (widget) => widget is CustomPaint && widget.painter != null,
            ),
          ),
        );
        final dynamic painter = paint.painter;
        return painter.frame.textureName as String;
      }

      expect(currentFrameName(), 'Kirb Bob0000');
      await tester.pump(const Duration(milliseconds: 20));
      expect(currentFrameName(), 'Kirb Bob0000');
      await tester.pump(const Duration(milliseconds: 30));
      expect(currentFrameName(), 'Kirb Bob0001');
      await tester.pump(const Duration(milliseconds: 75));
      expect(currentFrameName(), 'Kirb Bob0003');
      await tester.pump(const Duration(milliseconds: 375));
      expect(currentFrameName(), 'Kirb Bob0000');

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: SpriteWidget(name: testSpriteName, fps: 12),
        ),
      );
      await tester.pump(const Duration(milliseconds: 50));
      expect(currentFrameName(), 'Kirb Bob0000');
      await tester.pump(const Duration(milliseconds: 50));
      expect(currentFrameName(), 'Kirb Bob0001');
    });

    test('registers prefixes and orders all matching frames', () {
      final frames = SpriteFrameCollection()
        ..addFrame(const SpriteFrame(textureName: 'walk0010', rect: Rect.zero))
        ..addFrame(const SpriteFrame(textureName: 'walk0000', rect: Rect.zero))
        ..addFrame(const SpriteFrame(textureName: 'walk0001', rect: Rect.zero))
        ..addFrame(const SpriteFrame(textureName: 'jump 0000', rect: Rect.zero));
      final controller = SpriteAnimationController(prefixes: ['walk', 'jump']);
      addTearDown(controller.dispose);
      controller.attachFrames(frames);

      expect(frames.numOfFrames, 4);
      expect(frames.getFramesByPrefix('walk').map((frame) => frame.textureName),
          ['walk0000', 'walk0001', 'walk0010']);
      expect(frames.getFramesByPrefix('jump').single.frameNumber, 0);
      expect(() => controller.playLooped('missing'), throwsArgumentError);
      expect(() => controller.addAnimation('missing'), throwsArgumentError);

      controller.playLooped('walk');
      controller.playOnce('walk');
      expect(controller.currentAnimation, 'walk');
      expect(controller.isLooping, isTrue);
      controller.playOnce('jump');
      expect(controller.currentAnimation, 'jump');
      expect(controller.isLooping, isFalse);
      controller.stop();
      expect(controller.currentAnimation, isNull);
      controller.attachFrames(frames);
      controller.detachFrames(frames);
      expect(() => controller.addAnimation('missing'), throwsArgumentError);
      controller.detachFrames(frames);
      controller.addAnimation('missing');
    });

    testWidgets('plays only the registered animation on request', (tester) async {
      final controller = SpriteAnimationController(prefixes: ['Kirb Bob']);
      addTearDown(controller.dispose);
      await tester.runAsync(() async {
        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: SpriteWidget(
              name: testSpriteName,
              fps: 24,
              controller: controller,
            ),
          ),
        );
        for (var i = 0; i < 100; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 20));
          await tester.pump();
          if (find.byType(CircularProgressIndicator).evaluate().isEmpty) {
            break;
          }
        }
      });
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.textContaining('Error:'), findsNothing);

      final spritePaint = find.descendant(
        of: find.byType(SpriteWidget),
        matching: find.byWidgetPredicate(
          (widget) => widget is CustomPaint && widget.painter != null,
        ),
      );
      String currentFrameName() {
        final dynamic painter = tester.widget<CustomPaint>(spritePaint).painter;
        return painter.frame.textureName as String;
      }

      expect(spritePaint, findsNothing);
      controller.playOnce('Kirb Bob');
      await tester.pump();
      expect(currentFrameName(), 'Kirb Bob0000');
      await tester.pump(const Duration(milliseconds: 50));
      expect(currentFrameName(), 'Kirb Bob0001');
      controller.playOnce('Kirb Bob');
      await tester.pump(const Duration(milliseconds: 450));
      expect(currentFrameName(), 'Kirb Bob0011');
      await tester.pump(const Duration(milliseconds: 200));
      expect(currentFrameName(), 'Kirb Bob0011');
      controller.stop();
      await tester.pump();
      expect(spritePaint, findsNothing);
      controller.playLooped('Kirb Bob');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 550));
      expect(currentFrameName(), 'Kirb Bob0001');
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('switches between atlas prefixes and honors queued playback', (tester) async {
      final controller = SpriteAnimationController(
        prefixes: ['kirb groove', 'kirb hurt'],
      );
      addTearDown(controller.dispose);
      controller.playLooped('kirb groove');
      await tester.runAsync(() async {
        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: SpriteWidget(name: 'Kirb', fps: 24, controller: controller),
          ),
        );
        for (var i = 0; i < 250; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 20));
          await tester.pump();
          if (find.byType(CircularProgressIndicator).evaluate().isEmpty) {
            break;
          }
        }
      });
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.textContaining('Error:'), findsNothing);

      final spritePaint = find.descendant(
        of: find.byType(SpriteWidget),
        matching: find.byWidgetPredicate(
          (widget) => widget is CustomPaint && widget.painter != null,
        ),
      );
      String currentFrameName() {
        final dynamic painter = tester.widget<CustomPaint>(spritePaint).painter;
        return painter.frame.textureName as String;
      }

      expect(currentFrameName(), 'kirb groove0000');
      await tester.pump(const Duration(milliseconds: 50));
      expect(currentFrameName(), 'kirb groove0001');
      controller.playOnce('kirb hurt');
      await tester.pump();
      expect(currentFrameName(), 'kirb hurt0000');
      await tester.pump(const Duration(milliseconds: 400));
      expect(currentFrameName(), 'kirb hurt0008');
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('grid sprites share playback when one is tapped', (tester) async {
      await tester.runAsync(() async {
        await tester.pumpWidget(
          const MaterialApp(home: MyHomePage()),
        );
        for (var i = 0; i < 250; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 20));
          await tester.pump();
          if (find.byType(CircularProgressIndicator).evaluate().isEmpty) {
            break;
          }
        }
      });
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.textContaining('Error:'), findsNothing);
      final sprites = find.byType(SpriteWidget);
      expect(sprites.evaluate().length, greaterThan(1));
      final spritePaint = find.descendant(
        of: find.byType(SpriteWidget),
        matching: find.byWidgetPredicate(
          (widget) => widget is CustomPaint && widget.painter != null,
        ),
      );
      List<String> currentFrameNames() => tester
          .widgetList<CustomPaint>(spritePaint)
          .map((paint) {
            final dynamic painter = paint.painter;
            return painter.frame.textureName as String;
          })
          .toList();

      expect(currentFrameNames().length, sprites.evaluate().length);
      expect(currentFrameNames(), everyElement(startsWith('kirb groove')));
      final painters = tester.widgetList<CustomPaint>(spritePaint).toList();
      final dynamic firstPainter = painters.first.painter;
      for (final paint in painters.skip(1)) {
        final dynamic painter = paint.painter;
        expect(identical(painter.image, firstPainter.image), isTrue);
      }
      await tester.tap(sprites.first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));
      expect(currentFrameNames(), everyElement(startsWith('kirb hurt')));
      await tester.drag(find.byType(GridView), const Offset(0, -400));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.textContaining('Error:'), findsNothing);
      expect(currentFrameNames(), everyElement(startsWith('kirb hurt')));
      await tester.pumpWidget(const SizedBox());
      expect(tester.takeException(), isNull);
    });

    test('Retrieve spriteImage Atlas',(){
      final imageFile = File('assets/sprites/$testSpriteName.png');
      
      expect(imageFile.existsSync(), true, 
        reason: 'Image file should exist at assets/sprites/$testSpriteName.png');
      
      expect(imageFile.lengthSync(), greaterThan(0),
        reason: 'Image file should not be empty');
      
      debugPrint('Image file exists: ${imageFile.path}');
      debugPrint('File size: ${imageFile.lengthSync()} bytes');
    });

    test('tester to read xml spritesheet', () async {
      final assetManifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      final xmlPath = assetManifest.listAssets().firstWhere((asset) => asset.contains(testSpriteName) && asset.endsWith('.xml'));
      final xmlString = await rootBundle.loadString(xmlPath);
      final doc = XmlDocument.parse(xmlString);
      
      // Get the root TextureAtlas element
      var textureAtlas = doc.findElements('TextureAtlas').first;
      var imageName = textureAtlas.getAttribute('imagePath');
      
      expect(imageName, testSpriteName);
      
      // Verify there are SubTexture elements
      var subTextures = textureAtlas.findElements('SubTexture');
      expect(subTextures.length, greaterThan(0));
      
      debugPrint('TextureAtlas imagePath: $imageName');
      debugPrint('Number of SubTextures: ${subTextures.length}');

      for(var texture in subTextures){
        var name = texture.getAttribute('name');
        debugPrint('SubTexture: $name');
      }
    });
  });
}
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:panel_puzzle/sprite/sprite.dart';
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
        return painter.frame.name as String;
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
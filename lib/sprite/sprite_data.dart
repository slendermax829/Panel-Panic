import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:mime/mime.dart';
import 'package:panel_puzzle/sprite/sprite_frame.dart';
import 'package:xml/xml.dart';

class SpriteAtlasData{
  final ui.Image image;
  final SpriteFrameCollection frameCollection;

  SpriteAtlasData({
    required this.image,
    required this.frameCollection
  });
}

class SpriteDataCollection{
  static final Map<String, SpriteAtlasData> _spriteCache = {};
  static int _references = 0;

  static Future<SpriteAtlasData> acquireData(String filename) async {
    if(_spriteCache[filename] != null) return _spriteCache[filename]!;

    final loadedData = await _load(filename);
    final data = _spriteCache.putIfAbsent(filename, () => loadedData);
    _references++;

    return data;
  }

  static release(String filename){
    _spriteCache.remove(filename);
    _references --;
  }

  static Future<SpriteAtlasData> _load(String filename) async{
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final imgPath = manifest.listAssets().firstWhere((asset) => asset.endsWith('/$filename.png'));
    final xmlPath = manifest.listAssets().firstWhere((asset) => asset.endsWith('/$filename.xml'));

    final image = await atlasSourceImage(imgPath);
    final spriteFrames = await atlasSpriteFrames(xmlPath);

    return SpriteAtlasData(image: image, frameCollection: spriteFrames);
  }

  static Future<ui.Image> atlasSourceImage(String imgPath) async{
    final ByteData data = await rootBundle.load(imgPath);
    final Uint8List bytes = data.buffer.asUint8List();

    return await decodeImageFromList(bytes);
  }

  static Future<SpriteFrameCollection> atlasSpriteFrames(String xmlPath) async{
    final xmlString = await rootBundle.loadString(xmlPath);
    final xmlDoc = XmlDocument.parse(xmlString);

    final frameCollection = SpriteFrameCollection();

    for(var element in xmlDoc.findAllElements('SubTexture')){
      final name = element.getAttribute('name')!;

      final x = double.parse(element.getAttribute('x')!);
      final y = double.parse(element.getAttribute('y')!);
      final width = double.parse(element.getAttribute('width')!);
      final height = double.parse(element.getAttribute('height')!);

      final frameX =  double.parse(element.getAttribute('frameX') ?? '0');
      final frameY = double.parse(element.getAttribute('frameY') ?? '0');

      final frameWidth = double.parse(
        element.getAttribute('frameWidth') ?? '$width',
      );

      final frameHeight = double.parse(
        element.getAttribute('frameHeight') ?? '$height',
      );

      final SpriteFrame frame = SpriteFrame(
        textureName: name,
        srcRect: Rect.fromLTWH(x, y, width, height),
        trimOffset: Offset(-frameX, -frameY),
        originalSize: Size(frameWidth, frameHeight)
      );

      frameCollection.addFrame(frame);
    }
    return frameCollection;
  }
}

import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
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
  static final Map<String, Future<SpriteAtlasData>> _loading = {};

  static int _references = 0;

  static int get numOfAssetsLoaded => _spriteCache.length;

  /// Loads and caches every PNG/XML atlas pair declared under assets/sprites.
  static Future<void> loadAll() async{
    const spritePath = 'assets/sprites/';
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);

    final paths = manifest.listAssets().where((path) => path.startsWith(spritePath)).toSet();
    final stems = paths
        .where((path) => path.endsWith('.png') || path.endsWith('.xml'))
        .map((path) => path.substring(0, path.length - 4))
        .toSet()
        .toList()..sort();

    if (stems.isEmpty) {
      throw StateError('No sprite atlases found under $spritePath');
    }

    final filenames = <String>{};

    for (final stem in stems) {
      if (!paths.contains('$stem.png') || !paths.contains('$stem.xml')) {
        throw StateError('Sprite atlas requires both $stem.png and $stem.xml');
      }
      final filename = stem.substring(stem.lastIndexOf('/') + 1);

      if (!filenames.add(filename)) {
        throw StateError('Duplicate sprite atlas name: $filename found');
      }
    }
    for (final filename in filenames) {
      await acquireData(filename);
    }
  }

  static Future<SpriteAtlasData> acquireData(String filename) async {
    if(_spriteCache[filename] != null) return _spriteCache[filename]!;

    final pending = _loading[filename];
    if (pending != null) return pending;
    final future = _load(filename);
    _loading[filename] = future;
    try {
      final data = await future;
      _spriteCache[filename] = data;
      _references++;
      return data;
    } finally {
      _loading.remove(filename);
    }
  }

  static release(String filename){
    _spriteCache.remove(filename);
    _references --;
  }

  static Future<SpriteAtlasData> _load(String filename) async{
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final assets = manifest.listAssets();

    final images = assets.where((asset) =>
        asset.startsWith('assets/sprites/') && asset.endsWith('/$filename.png')).toList();

    final xmlFiles = assets.where((asset) =>
        asset.startsWith('assets/sprites/') && asset.endsWith('/$filename.xml')).toList();

    if (images.length != 1 || xmlFiles.length != 1 || images.single.substring(0, images.single.length - 4) != xmlFiles.single.substring(0, xmlFiles.single.length - 4)) {
      throw StateError('Expected one matching PNG/XML sprite atlas for "$filename"');
    }

    final image = await atlasSourceImage(images.single);
    try {
      final spriteFrames = await atlasSpriteFrames(xmlFiles.single);
      return SpriteAtlasData(image: image, frameCollection: spriteFrames);
    } catch (_) {
      image.dispose();
      rethrow;
    }
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

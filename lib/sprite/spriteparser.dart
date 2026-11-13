import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:panel_puzzle/sprite/sprite_frame.dart';
import 'package:xml/xml.dart';
import 'dart:ui' as ui;

Future<ui.Image> atlasSourceImg(String imgPath) async{
  final ByteData data = await rootBundle.load(imgPath);
  final Uint8List bytes = data.buffer.asUint8List();

  return await decodeImageFromList(bytes);
}

Future<SpriteFrameCollection> atlasSpriteFrames(String path) async{
  final xmlString = await rootBundle.loadString(path);
  final doc = XmlDocument.parse(xmlString);

  final frameCollection = SpriteFrameCollection();

  for(var element in doc.findAllElements('SubTexture')){
    final name = element.getAttribute('name')!;

    final x = double.parse(element.getAttribute('x')!);
    final y = double.parse(element.getAttribute('y')!);
    final width = double.parse(element.getAttribute('width')!);
    final height = double.parse(element.getAttribute('height')!);

    final SpriteFrame frame = SpriteFrame(
      textureName: name,
      rect: Rect.fromLTWH(
        x, 
        y, 
        width, 
        height
      )
    );

    frameCollection.addFrame(frame);
  }

  return frameCollection;
}
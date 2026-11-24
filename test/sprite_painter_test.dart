import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:panel_puzzle/sprite/sprite.dart';
import 'package:panel_puzzle/sprite/sprite_data.dart';
import 'package:panel_puzzle/sprite/sprite_frame.dart';

void main() {
  testWidgets('draws trimmed frames at scale and flips within original bounds',
      (tester) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawRect(const Rect.fromLTWH(0, 0, 2, 2), Paint()..color = Colors.red);
    canvas.drawRect(const Rect.fromLTWH(2, 0, 2, 2), Paint()..color = Colors.blue);
    final image = (await tester.runAsync(() => recorder.endRecording().toImage(4, 2)))!;
    addTearDown(image.dispose);
    final frames = SpriteFrameCollection()
      ..addFrame(const SpriteFrame(
        textureName: 'red0000',
        srcRect: Rect.fromLTWH(0, 0, 2, 2),
        trimOffset: Offset(1, 1),
        originalSize: Size(5, 5),
      ))
      ..addFrame(const SpriteFrame(
        textureName: 'blue0000',
        srcRect: Rect.fromLTWH(2, 0, 2, 2),
        trimOffset: Offset(1, 1),
        originalSize: Size(5, 5),
      ));
    final atlas = SpriteAtlasData(image: image, frameCollection: frames);
    final key = GlobalKey();

    Future<ui.Image> render(String name, {bool flipX = false, bool flipY = false}) async {
      await tester.pumpWidget(Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: RepaintBoundary(
            key: key,
            child: Sprite(
              atlas: atlas,
              frameName: name,
              width: 2,
              height: 2,
              flipX: flipX,
              flipY: flipY,
            ),
          ),
        ),
      ));
      final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      return (await tester.runAsync(() => boundary.toImage()))!;
    }

    Future<Color> pixel(ui.Image image, int x, int y) async {
      final data = (await tester.runAsync(
        () => image.toByteData(format: ui.ImageByteFormat.rawRgba),
      ))!;
      final offset = (y * image.width + x) * 4;
      return Color.fromARGB(
        data.getUint8(offset + 3),
        data.getUint8(offset),
        data.getUint8(offset + 1),
        data.getUint8(offset + 2),
      );
    }

    final first = await render('red0000');
    expect(first.width, 10);
    expect(first.height, 10);
    expect(await pixel(first, 1, 1), Colors.transparent);
    expect(await pixel(first, 2, 2), Colors.red.shade500);
    expect(await pixel(first, 5, 5), Colors.red.shade500);
    expect(await pixel(first, 6, 6), Colors.transparent);
    first.dispose();

    final flipped = await render('red0000', flipX: true, flipY: true);
    expect(await pixel(flipped, 2, 2), Colors.transparent);
    expect(await pixel(flipped, 4, 4), Colors.red.shade500);
    expect(await pixel(flipped, 7, 7), Colors.red.shade500);
    expect(await pixel(flipped, 8, 8), Colors.transparent);
    flipped.dispose();

    final nextFrame = await render('blue0000', flipX: true, flipY: true);
    expect(await pixel(nextFrame, 4, 4), Colors.blue.shade500);
    nextFrame.dispose();
  });
}

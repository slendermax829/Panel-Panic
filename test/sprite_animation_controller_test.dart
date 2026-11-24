import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:panel_puzzle/sprite/sprite_animation_controller.dart';
import 'package:panel_puzzle/sprite/sprite_data.dart';
import 'package:panel_puzzle/sprite/sprite_frame.dart';

void main() {
  Future<SpriteAnimationController> createController(WidgetTester tester) async {
    final recorder = ui.PictureRecorder();
    Canvas(recorder).drawRect(const Rect.fromLTWH(0, 0, 1, 1), Paint());
    final image = (await tester.runAsync(() => recorder.endRecording().toImage(1, 1)))!;
    addTearDown(image.dispose);
    final frames = SpriteFrameCollection();
    for (final name in ['walk0010', 'walk0000', 'walk0003', 'jump0000']) {
      frames.addFrame(SpriteFrame(
        textureName: name,
        srcRect: const Rect.fromLTWH(0, 0, 1, 1),
        trimOffset: Offset.zero,
        originalSize: const Size(1, 1),
      ));
    }
    final controller = SpriteAnimationController(
      atlas: SpriteAtlasData(image: image, frameCollection: frames),
      vsync: tester,
      defaultFps: 10,
    );
    addTearDown(controller.dispose);
    return controller;
  }

  testWidgets('duration playback stops on the frame reached at the deadline', (tester) async {
    final controller = await createController(tester);
    var completions = 0;
    controller.playLoopedDuration('walk', const Duration(milliseconds: 250),
        onComplete: () => completions++);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(controller.currentFrame, 'walk0003');
    await tester.pump(const Duration(milliseconds: 400));
    expect(controller.currentFrame, 'walk0010');
    expect(controller.isPlaying, isFalse);
    expect(completions, 1);
    await tester.pump(const Duration(seconds: 1));
    expect(completions, 1);
    expect(() => controller.playLoopedDuration('walk', Duration.zero), throwsArgumentError);
  });

  testWidgets('pausing preserves remaining playback duration', (tester) async {
    final controller = await createController(tester);
    var completions = 0;
    controller.playLoopedDuration('walk', const Duration(milliseconds: 250),
        onComplete: () => completions++);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));
    controller.pause();
    expect(controller.isPlaying, isFalse);
    await tester.pump(const Duration(seconds: 1));
    expect(controller.currentFrame, 'walk0003');
    controller.resume();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 99));
    expect(controller.isPlaying, isTrue);
    await tester.pump(const Duration(milliseconds: 1));
    expect(controller.currentFrame, 'walk0010');
    expect(controller.isPlaying, isFalse);
    expect(completions, 1);
  });

  testWidgets('a duration shorter than one frame still completes', (tester) async {
    final controller = await createController(tester);
    var completions = 0;
    controller.playLoopedDuration('walk', const Duration(milliseconds: 50),
        onComplete: () => completions++);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(controller.currentFrame, 'walk0000');
    expect(controller.isPlaying, isFalse);
    expect(completions, 1);
  });

  testWidgets('setOnFrame starts at the numbered frame and completes playback', (tester) async {
    final controller = await createController(tester);
    var completions = 0;
    var notifications = 0;
    controller.addListener(() => notifications++);
    controller.setOnFrame('walk', 3, onComplete: () => completions++);
    expect(controller.currentFrame, 'walk0003');
    expect(controller.isPlaying, isTrue);
    expect(notifications, 1);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(controller.currentFrame, 'walk0010');
    await tester.pump(const Duration(milliseconds: 100));
    expect(controller.isPlaying, isFalse);
    expect(completions, 1);
    expect(() => controller.setOnFrame('walk', 1), throwsArgumentError);
    expect(() => controller.setOnFrame('missing', 0), throwsArgumentError);
  });

  testWidgets('new playback cancels an earlier duration and callback', (tester) async {
    final controller = await createController(tester);
    var completions = 0;
    controller.playLoopedDuration('walk', const Duration(milliseconds: 200),
        onComplete: () => completions++);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    controller.play('jump', loop: true);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(controller.currentFrame, 'jump0000');
    expect(controller.isPlaying, isTrue);
    expect(completions, 0);
    controller.pause();
  });
}

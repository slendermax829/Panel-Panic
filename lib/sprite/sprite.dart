import 'package:flutter/material.dart';
import 'dart:ui' as ui;

import 'package:panel_puzzle/sprite/sprite_animation_controller.dart';
import 'package:panel_puzzle/sprite/sprite_data.dart';
import 'package:panel_puzzle/sprite/sprite_frame.dart';

class AnimatedSprite extends StatelessWidget {
  final SpriteAnimationController controller;
  final double width;
  final double height;
  final bool flipX;
  final bool flipY;
  final FilterQuality filterQuality;

  const AnimatedSprite({
    super.key,
    required this.controller,
    this.width = 1.0,
    this.height = 1.0,
    this.flipX = false,
    this.flipY = false,
    this.filterQuality = .none
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller, 
      builder:(context, _) {
        if(controller.currentFrame.isEmpty){
          return const SizedBox.shrink(); // nothing
        }
        return Sprite(
          atlas: controller.atlas,
          frameName: controller.currentFrame,
          width: width,
          height: height,
          flipX: flipX,
          flipY: flipY,
          filterQuality: filterQuality,
        );
      }
    );
  }
}

class Sprite extends StatelessWidget {
  final SpriteAtlasData atlas;
  final String frameName;
  /// Horizontal and vertical scale factors relative to the original frame size.
  final double width;
  final double height;
  final bool flipX;
  final bool flipY;
  final FilterQuality filterQuality;

  const Sprite({
    super.key,
    required this.atlas,
    required this.frameName,
    this.width = 1,
    this.height = 1,
    this.flipX = false,
    this.flipY = false,
    this.filterQuality = .none
  });

  @override
  Widget build(BuildContext context) {
    final frame = atlas.frameCollection.getFrameByName(frameName: frameName);
    
    if(frame == null){
      throw FlutterError('Sprite frame not found: $frameName');
    }

    return SizedBox(
      width: frame.originalSize.width * width,
      height: frame.originalSize.height * height,
      child: CustomPaint(
        painter: _SpritePainter(
          image: atlas.image, 
          frame: frame,
          flipX: flipX, 
          flipY: flipY, 
          filterQuality: filterQuality),
      ),
    );
  }
}

class _SpritePainter extends CustomPainter{
  final ui.Image image;
  final SpriteFrame frame;
  final bool flipX;
  final bool flipY;
  final FilterQuality filterQuality;

  final Paint _paint = Paint();

  _SpritePainter({
    required this.image, 
    required this.frame,
    required this.flipX, 
    required this.flipY, 
    required this.filterQuality
  });


  @override
  void paint(Canvas canvas, Size size) {
    final scaleX = size.width / frame.originalSize.width;
    final scaleY = size.height / frame.originalSize.height;
    canvas.save();

    if(flipX || flipY){
      canvas.translate(
        flipX ? size.width : 0,
        flipY ? size.height : 0
      );

      canvas.scale(
        flipX ? -1.0 : 1.0,
        flipY ? -1.0 : 1.0
      );
    }

    final dstRect = Rect.fromLTWH(
      frame.trimOffset.dx * scaleX,
      frame.trimOffset.dy * scaleY,
      frame.srcRect.width * scaleX,
      frame.srcRect.height * scaleY,
    );

    canvas.drawImageRect(
      image,
      frame.srcRect,
      dstRect,
      _paint..filterQuality = filterQuality,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _SpritePainter oldDelegate) {
    return oldDelegate.image != image ||
        oldDelegate.frame != frame ||
        oldDelegate.flipX != flipX ||
        oldDelegate.flipY != flipY ||
        oldDelegate.filterQuality != filterQuality;
  }

}
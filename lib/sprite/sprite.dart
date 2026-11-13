import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:panel_puzzle/sprite/sprite_frame.dart';
import 'dart:ui' as ui;
import 'spriteparser.dart' as  SpriteParser;
class SpriteWidget extends StatefulWidget {
  final String name;
  final int fps;
  final double width;
  final double height;
  final FilterQuality filterQuality;

  SpriteWidget({
    super.key,
    required this.name,
    this.fps = 12,
    this.width = 100,
    this.height = 100,
    this.filterQuality = FilterQuality.medium,
  }) : assert(fps > 0);

  SpriteWidget.squared({
    super.key,
    required this.name,
    this.fps = 12,
    double size = 100,
    this.filterQuality = FilterQuality.medium,
  }) : width = size, height = size, assert(fps > 0);

  @override
  State<SpriteWidget> createState() => _SpriteWidgetState();
}

class _SpriteWidgetState extends State<SpriteWidget> with SingleTickerProviderStateMixin{
  late final AnimationController _animationController;
  late final Future<void> _spriteLoadingFuture;
  late final ui.Image _sourceImage;
  late final SpriteFrameCollection _frames;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
    );
    _spriteLoadingFuture = _loadSprite();
  }

  Future<void> _loadSprite() async {
    final assetManifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final imgPath = assetManifest.listAssets().firstWhere((asset) => asset.contains(widget.name) && asset.endsWith('.png'));
    final xmlPath = assetManifest.listAssets().firstWhere((asset) => asset.contains(widget.name) && asset.endsWith('.xml'));

    _sourceImage = await SpriteParser.atlasSourceImg(imgPath);
    _frames = await SpriteParser.atlasSpriteFrames(xmlPath);
    if (_frames.numOfFrames == 0) {
      throw StateError('Sprite "${widget.name}" has no frames');
    }
    if (mounted) {
      _startAnimation();
    }
  }

  void _startAnimation() {
    _animationController.duration = Duration(
      microseconds: (Duration.microsecondsPerSecond *
              _frames.numOfFrames /
              widget.fps)
          .round(),
    );
    _animationController.repeat();
  }

  @override
  void didUpdateWidget(covariant SpriteWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.fps != widget.fps && _animationController.isAnimating) {
      _startAnimation();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _spriteLoadingFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return SizedBox(
            width: widget.width,
            height: widget.height,
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return SizedBox(
            width: widget.width,
            height: widget.height,
            child: Center(child: Text('Error: ${snapshot.error}')),
          );
        }

        return AnimatedBuilder(
          animation: _animationController, 
          builder: (context, child) {
            final frameIndex = (_animationController.value * _frames.numOfFrames).floor() % _frames.numOfFrames;

            return CustomPaint(
              size: Size(widget.width, widget.height),
              painter: _SpritePainter(
                image: _sourceImage,
                frame: _frames[frameIndex],
                filterQuality: widget.filterQuality
              )
            );
          },
        );
      },
    );
  }
}

class _SpritePainter extends CustomPainter{
  final ui.Image image;
  final SpriteFrame frame;
  final FilterQuality filterQuality;

  _SpritePainter({
    required this.image,
    required this.frame,
    required this.filterQuality
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..filterQuality = filterQuality;

    canvas.drawImageRect(
      image,
      frame.rect,
      Rect.fromLTWH(0, 0, size.width, size.height),
      paint
    );
  }

  @override
  bool shouldRepaint(covariant _SpritePainter oldDelegate) {
    return oldDelegate.frame != frame;
  }

}
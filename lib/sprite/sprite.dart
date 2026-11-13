import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:panel_puzzle/sprite/sprite_animation.dart';
import 'package:panel_puzzle/sprite/sprite_frame.dart';
import 'dart:ui' as ui;
import 'spriteparser.dart' as  SpriteParser;

class SpriteWidget extends StatefulWidget {
  final String name;
  final int fps;
  final double width;
  final double height;
  final FilterQuality filterQuality;
  final SpriteAnimationController? controller;
  final VoidCallback? onTap;

  SpriteWidget({
    super.key,
    required this.name,
    this.fps = 12,
    this.width = 100,
    this.height = 100,
    this.filterQuality = FilterQuality.medium,
    this.controller,
    this.onTap
  }) : assert(fps > 0);

  SpriteWidget.squared({
    super.key,
    required this.name,
    this.fps = 12,
    double size = 100,
    this.filterQuality = FilterQuality.medium,
    this.controller,
    this.onTap
  }) : width = size, height = size, assert(fps > 0);

  @override
  State<SpriteWidget> createState() => _SpriteWidgetState();
}

class _SpriteWidgetState extends State<SpriteWidget> with SingleTickerProviderStateMixin{
  late final AnimationController _animationController;
  late final Future<void> _spriteLoadingFuture;
  late final ui.Image _sourceImage;
  late final SpriteFrameCollection _frames;
  List<SpriteFrame> _activeFrames = [];
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
    );
    widget.controller?.addListener(_onAnimationChanged);
    _spriteLoadingFuture = _loadSprite();
  }

  Future<void> _loadSprite() async {
    final assetManifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final imgPath = assetManifest.listAssets().firstWhere((asset) => asset.endsWith('/${widget.name}.png'));
    final xmlPath = assetManifest.listAssets().firstWhere((asset) => asset.endsWith('/${widget.name}.xml'));

    _sourceImage = await SpriteParser.atlasSourceImg(imgPath);
    _frames = await SpriteParser.atlasSpriteFrames(xmlPath);
    if (_frames.numOfFrames == 0) {
      throw StateError('Sprite "${widget.name}" has no frames');
    }
    if (mounted) {
      widget.controller?.attachFrames(_frames);
      _loaded = true;
      if (widget.controller == null) {
        _activeFrames = [for (final index in _frames.indices) _frames[index]];
        _startAnimation(looping: true);
      } else {
        _onAnimationChanged();
      }
    }
  }

  void _startAnimation({required bool looping}) {
    _animationController.duration = Duration(
      microseconds: (Duration.microsecondsPerSecond *
              _activeFrames.length /
              widget.fps)
          .round(),
    );
    if (looping) {
      _animationController.repeat();
    } else {
      _animationController.forward(from: 0);
    }
  }

  void _onAnimationChanged() {
    if (!_loaded) return;
    _animationController.stop();
    final controller = widget.controller;
    final prefix = controller?.currentAnimation;
    _activeFrames = prefix == null ? [] : _frames.getFramesByPrefix(prefix);
    if (_activeFrames.isNotEmpty) {
      _animationController.value = 0;
      _startAnimation(looping: controller!.isLooping);
    }
    if (mounted) setState(() {});
  }

  @override
  void didUpdateWidget(covariant SpriteWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?.removeListener(_onAnimationChanged);
      if (_loaded) oldWidget.controller?.detachFrames(_frames);
      widget.controller?.addListener(_onAnimationChanged);
      if (_loaded) {
        widget.controller?.attachFrames(_frames);
        if (widget.controller == null) {
          _activeFrames = [for (final index in _frames.indices) _frames[index]];
          _animationController.value = 0;
          _startAnimation(looping: true);
        } else {
          _onAnimationChanged();
        }
      }
    } else if (oldWidget.fps != widget.fps && _animationController.isAnimating) {
      final value = _animationController.value;
      _animationController.duration = Duration(
        microseconds: (Duration.microsecondsPerSecond * _activeFrames.length / widget.fps).round(),
      );
      if (widget.controller?.isLooping ?? true) {
        _animationController.repeat();
      } else {
        _animationController.forward(from: value);
      }
    }
  }

  @override
  void dispose() {
    widget.controller?.removeListener(_onAnimationChanged);
    if (_loaded) widget.controller?.detachFrames(_frames);
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
          return GestureDetector(
            onTap: widget.onTap,
            child: SizedBox(
              width: widget.width,
              height: widget.height,
              child: Center(child: Text('Error: ${snapshot.error}')),
            ),
          );
        }

        if (_activeFrames.isEmpty) {
          return SizedBox(width: widget.width, height: widget.height);
        }
        return GestureDetector(
          onTap: widget.onTap,
          child: AnimatedBuilder(
            animation: _animationController, 
            builder: (context, child) {
              final frameIndex = (_animationController.value * _activeFrames.length)
                  .floor().clamp(0, _activeFrames.length - 1);
          
              return CustomPaint(
                size: Size(widget.width, widget.height),
                painter: _SpritePainter(
                  image: _sourceImage,
                  frame: _activeFrames[frameIndex],
                  filterQuality: widget.filterQuality
                )
              );
            },
          ),
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
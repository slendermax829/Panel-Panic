import 'package:flutter/material.dart';
import 'package:panel_puzzle/sprite/sprite.dart';
import 'package:panel_puzzle/sprite/sprite_animation_controller.dart';
import 'package:panel_puzzle/sprite/sprite_data.dart';

class CustomPanel extends StatefulWidget {
  final String _filename = 'Panel';

  final bool isFlipped;
  final bool isBlocked;

  const CustomPanel({
    super.key,
    required this.isFlipped,
    this.isBlocked = false,
  });

  @override
  State<CustomPanel> createState() => _CustomPanelState();
}

class _CustomPanelState extends State<CustomPanel>
    with SingleTickerProviderStateMixin {
  SpriteAnimationController? _panelController;

  @override
  void initState() {
    super.initState();
    _setup();
  }

  @override
  void didUpdateWidget(covariant CustomPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    final controller = _panelController;
    if (controller == null) return;

    if (oldWidget.isFlipped != widget.isFlipped) {
      _flipPanel();
    } else if (oldWidget.isBlocked != widget.isBlocked) {
      _showStaticFrame(controller);
    }
  }

  @override
  void dispose() {
    _panelController?.dispose();
    super.dispose();
  }

  void _setup() async {
    final atlas = await SpriteDataCollection.acquireData(widget._filename);
    if (!mounted) return;

    final controller = SpriteAnimationController(atlas: atlas, vsync: this);
    _showStaticFrame(controller);

    setState(() => _panelController = controller);
  }

  String get _currentPrefix => widget.isFlipped ? 'panel_flip_1' : 'panel_flip_2';
  String get _blockedPrefix => 'wrong panel';

  void _showStaticFrame(SpriteAnimationController controller) {
    if (widget.isBlocked) {
      _showBlockedFrame(controller);
    } else {
      _showCurrentFrame(controller);
    }
  }

  void _showCurrentFrame(SpriteAnimationController controller) {
    final frame = controller.atlas.frameCollection
                  .getFramesByPrefix(prefix: _currentPrefix)
                  .last;

    controller.setOnFrame(_currentPrefix, frame.frameNumber);
    controller.pause();
  }

  void _showBlockedFrame(SpriteAnimationController controller){
    final frame = controller.atlas.frameCollection
                  .getFramesByPrefix(prefix: _blockedPrefix)
                  .last;

    controller.setOnFrame(_blockedPrefix, frame.frameNumber);
    controller.pause();
  }

  void _flipPanel() {
    _panelController?.play(
      _currentPrefix,
      loop: false,
      fps: 24,
      onComplete: () {
        final controller = _panelController;
        if (controller != null) _showStaticFrame(controller);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = _panelController;

    if (controller == null)
      return const Center(child: CircularProgressIndicator());

    return Stack(
      fit: StackFit.expand,
      children: [
        AnimatedSprite(controller: controller),
      ],
    );
  }
}

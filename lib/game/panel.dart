import 'package:flutter/material.dart';
import 'package:panel_puzzle/sprite/sprite.dart';
import 'package:panel_puzzle/sprite/sprite_animation_controller.dart';
import 'package:panel_puzzle/sprite/sprite_data.dart';


class Panel extends StatefulWidget {
  final String _filename = 'Kirb';
  final bool isFlipped;
  final bool isVictory;
  final VoidCallback? onVictoryComplete;

  const Panel({
    super.key,
    required this.isFlipped,
    this.isVictory = false,
    this.onVictoryComplete,
  });

  @override
  State<Panel> createState() => _PanelState();
}

class _PanelState extends State<Panel> with SingleTickerProviderStateMixin{
  SpriteAnimationController? _panelController;
  Object? _loadError;

  @override
  void initState(){
    super.initState();
    _setup();
  }

  @override
  void didUpdateWidget(covariant Panel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isVictory && !oldWidget.isVictory) {
      final controller = _panelController;
      if (controller != null) _showVictory(controller);
    } else if (!widget.isVictory && oldWidget.isVictory) {
      final controller = _panelController;
      if (controller != null) _showCurrentFrame(controller);
    } else if (!widget.isVictory && oldWidget.isFlipped != widget.isFlipped) {
      _flipPanel();
    }
  }

  @override
  void dispose(){
    _panelController?.dispose();
    super.dispose();
  }

  Future<void> _setup() async{
    try{
      final atlas = await SpriteDataCollection.acquireData(widget._filename);
      if(!mounted) return;

      final newController = SpriteAnimationController(atlas: atlas, vsync: this);
      try{
        if (widget.isVictory) {
          _showVictory(newController);
        } else {
          _showCurrentFrame(newController);
        }
      }catch(_){
        newController.dispose();
        rethrow;
      }

      setState(() =>  _panelController = newController,);

    }catch (error, stackTrace) {
      if (mounted) {
        setState(() {
          _loadError = error;
        });
      } else {
        FlutterError.reportError(FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'sprite demo',
          context: ErrorDescription('while loading the sprite atlas'),
        ));
      }
    }
  }

  String get _currentPrefix => widget.isFlipped ? 'kirb groove' : 'kirb hurt';
  String get _clearPrefix => 'kirb victory';

  void _showCurrentFrame(SpriteAnimationController controller) {
    final frame = controller.atlas.frameCollection
        .getFramesByPrefix(prefix: _currentPrefix).last;
    controller.setOnFrame(_currentPrefix, frame.frameNumber);
    controller.pause();
  }

  void _flipPanel(){
    _panelController?.playLoopedDuration(
      _currentPrefix,
      const Duration(seconds: 1),
      fps: 24,
      onComplete: () {
        final controller = _panelController;
        if (controller != null) _showCurrentFrame(controller);
      },
    );
  }

  void _showVictory(SpriteAnimationController controller){
    controller.play(
      _clearPrefix,
      fps: 24,
      loop: false,
      onComplete: () {
        if (mounted && widget.isVictory) widget.onVictoryComplete?.call();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = _panelController;
    if (_loadError != null) {
      return Center(child: Text('Error loading sprite: $_loadError'));
    }
    if (controller == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return AnimatedSprite(
      controller: controller,
    );
  }
}
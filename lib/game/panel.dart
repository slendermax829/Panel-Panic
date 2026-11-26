import 'package:flutter/material.dart';
import 'package:panel_puzzle/sprite/sprite.dart';
import 'package:panel_puzzle/sprite/sprite_animation_controller.dart';
import 'package:panel_puzzle/sprite/sprite_data.dart';
class Panel extends StatefulWidget {
  final String _filename = 'Panel';

  final bool isFlipped;
  final bool isVictory;
  final bool isFailed;
  final VoidCallback? onVictoryComplete;
  final VoidCallback? onFailedComplete;

  const Panel.game({
    super.key,
    required this.isFlipped,
    this.isVictory = false,
    this.isFailed = false,
    this.onVictoryComplete,
    this.onFailedComplete
  });

  // const Panel.editor({

  // });

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

    } else if (widget.isFailed && !oldWidget.isFailed) {
      final controller = _panelController;
      if (controller != null) _showFailed(controller);

    } else if (!widget.isVictory && !widget.isFailed &&
        (oldWidget.isVictory || oldWidget.isFailed)) {
      final controller = _panelController;
      if (controller != null) _showCurrentFrame(controller);

    } else if (!widget.isVictory && !widget.isFailed &&
        oldWidget.isFlipped != widget.isFlipped) {
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
        } else if (widget.isFailed) {
          _showFailed(newController);
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

  String get _currentPrefix => widget.isFlipped ? 'panel_flip_1' : 'panel_flip_2';
  String get _clearPrefix => 'clear panel';
  String get _failedPrefix => 'wrong panel';

  void _showCurrentFrame(SpriteAnimationController controller) {
    final frame = controller.atlas.frameCollection.getFramesByPrefix(prefix: _currentPrefix).last;

    controller.setOnFrame(_currentPrefix, frame.frameNumber);
    controller.pause();
  }

  void _flipPanel(){
    _panelController?.play(
      _currentPrefix,
      loop: false,
      fps: 24,
      onComplete: (){
        final controller = _panelController;
        if(controller != null) _showCurrentFrame(controller);
      }
    );
  }

  void _showVictory(SpriteAnimationController controller){
    controller.play(
      _clearPrefix,
      fps: 24,
      loop: false,
      repeatCount: 2,
      onComplete: () {
        if (mounted && widget.isVictory) widget.onVictoryComplete?.call();
      },
    );
  }

  void _showFailed(SpriteAnimationController controller){
    controller.play(
      _failedPrefix,
      fps: 24,
      repeatCount: 6,
      onComplete: () {
        if (mounted && widget.isFailed) widget.onFailedComplete?.call();
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
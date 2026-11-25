import 'package:flutter/material.dart';
import 'package:panel_puzzle/game/panel.dart';
import 'package:panel_puzzle/sprite/sprite.dart';
import 'package:panel_puzzle/sprite/sprite_animation_controller.dart';
import 'package:panel_puzzle/sprite/sprite_data.dart';
class Board extends StatefulWidget {
  final _filename = 'Board';

  final int boardSize;
  final List<bool> panels;
  final bool isInteractive;
  final ValueChanged<int>? onPanelTap;
  final bool isVictory;
  final Set<int> failedPanels;
  final ValueChanged<int>? onVictoryComplete;
  final ValueChanged<int>? onFailedComplete;

  Board({
    super.key,
    required this.boardSize,
    required this.panels,
    required this.isInteractive,
    this.onPanelTap,
    this.isVictory = false,
    this.failedPanels = const {},
    this.onVictoryComplete,
    this.onFailedComplete
  });

  @override
  State<Board> createState() => _BoardState();
}

class _BoardState extends State<Board> with SingleTickerProviderStateMixin{
  SpriteAnimationController? _boardController;
  Object? _loadError;

  int _hoveredPanelIndex = -1;

  @override
  void initState() {
    super.initState();
    _setup();
  }

  @override
  void dispose() {
    _boardController?.dispose();
    super.dispose();
  }

  void _setup() async {
    final atlas = await SpriteDataCollection.acquireData(widget._filename);
    if(!mounted) return;

    final controller = SpriteAnimationController(atlas: atlas, vsync: this);

    try{
      controller.play(
        'board',
        loop: true,
        fps: 24
      );
    }catch(_){
      controller.dispose();
    }

    setState(() => _boardController = controller);
  }

  @override
  Widget build(BuildContext context) {
    final controller = _boardController;

    return Stack(
        children: [
          controller == null
              ? const SizedBox.shrink()
              : AspectRatio( aspectRatio: 1, child: AnimatedSprite(controller: controller)),
          Padding(
            padding: const EdgeInsets.all(25.0),
            child: AspectRatio(
              aspectRatio: 1,
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                itemCount: widget.panels.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: widget.boardSize,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8
                ), 
                itemBuilder:(context, index) {
                  final bool flippedPanel = widget.panels[index];
                
                  return MouseRegion(
                    cursor: widget.isInteractive ? SystemMouseCursors.click : MouseCursor.defer,
                    onHover: (event) {
                      if(widget.isInteractive){
                        setState(() => _hoveredPanelIndex = index);
                      }
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        border: _hoveredPanelIndex != index ? null : BoxBorder.all(color: Colors.orangeAccent)
                      ),
                      child: GestureDetector(
                        onTap: widget.isInteractive && widget.onPanelTap != null ? () => widget.onPanelTap!(index) : null,
                        child: Panel.game(
                          isFlipped: flippedPanel,
                          isVictory: widget.isVictory,
                          isFailed: widget.failedPanels.contains(index),
                          onVictoryComplete: widget.onVictoryComplete == null ? null : () => widget.onVictoryComplete!(index),
                          onFailedComplete: widget.onFailedComplete == null ? null : () => widget.onFailedComplete!(index),
                        )
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ]
      );
  }
}

import 'package:flutter/material.dart';
import 'package:panel_puzzle/custom_board/board_creation_mode.dart';
import 'package:panel_puzzle/custom_board/custom_panel.dart';
import 'package:panel_puzzle/sprite/sprite.dart';
import 'package:panel_puzzle/sprite/sprite_animation_controller.dart';
import 'package:panel_puzzle/sprite/sprite_data.dart';

class CustomBoard extends StatefulWidget {
  final _filename = 'Board';

  final int boardSize;
  final List<bool> panels;
  final ValueChanged<int>? onPanelTap;
  final CustomMode mode;
  final int? blockedPanel;

  CustomBoard({
    super.key,
    required this.boardSize,
    required this.panels,
    required this.mode,
    this.onPanelTap,
    this.blockedPanel,
  });

  @override
  State<CustomBoard> createState() => _CustomBoardState();
}

class _CustomBoardState extends State<CustomBoard>
    with SingleTickerProviderStateMixin {
  SpriteAnimationController? _boardController;

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
    if (!mounted) return;

    final controller = SpriteAnimationController(atlas: atlas, vsync: this);

    try {
      controller.play('board', loop: true, fps: 24);
    } catch (_) {
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
            : AspectRatio(
                aspectRatio: 1,
                child: AnimatedSprite(controller: controller),
              ),
        Padding(
          padding: const EdgeInsets.all(40.0),
          child: AspectRatio(
            aspectRatio: 1,
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.panels.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: widget.boardSize,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
              ),
              itemBuilder: (context, index) {
                final bool flippedPanel = widget.panels[index];

                return MouseRegion(
                  cursor: SystemMouseCursors.click,
                  onHover: (event) =>
                      setState(() => _hoveredPanelIndex = index),
                  child: Container(
                    decoration: BoxDecoration(
                      border: widget.mode == .Design
                          ? _hoveredPanelIndex != index
                                ? null
                                : Border.all(color: Colors.lightGreen)
                          : _hoveredPanelIndex != index
                          ? null
                          : Border.all(color: Colors.yellowAccent),
                    ),
                    child: GestureDetector(
                      onTap: widget.onPanelTap != null
                          ? () => widget.onPanelTap!(index)
                          : null,
                      child: CustomPanel(
                        isFlipped: flippedPanel,
                        isBlocked:
                            widget.mode == .Puzzle &&
                            widget.blockedPanel == index,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

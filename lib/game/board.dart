import 'package:flutter/material.dart';
import 'package:panel_puzzle/game/panel.dart';

const Map<String,Color> _panelColors= {
  'front' : Colors.tealAccent,
  'back' : Colors.pink
};

const Map<String,Icon> _panelIcons = {
  'front' : Icon(Icons.diamond),
  'back' : Icon(Icons.heart_broken)
};

class Board extends StatelessWidget {
  final int boardSize;
  final List<bool> panels;
  final bool isInteractive;
  final ValueChanged<int>? onPanelTap;
  final bool isVictory;
  final ValueChanged<int>? onVictoryComplete;

  Board({
    super.key,
    required this.boardSize,
    required this.panels,
    required this.isInteractive,
    this.onPanelTap,
    this.isVictory = false,
    this.onVictoryComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(5),
      decoration: BoxDecoration(
        border: Border.all(
          color: !isInteractive ? Colors.yellowAccent : Colors.blue
        ),
      ),
      child: AspectRatio(
        aspectRatio: 1,
        child: GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          itemCount: panels.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: boardSize,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8
          ), 
          itemBuilder:(context, index) {
            final bool flippedPanel = panels[index];

            return GestureDetector(
              onTap: isInteractive && onPanelTap != null
                      ? () => onPanelTap!(index)
                      : null,
              child: Panel(
                isFlipped: flippedPanel,
                isVictory: isVictory,
                onVictoryComplete: onVictoryComplete == null
                    ? null
                    : () => onVictoryComplete!(index),
              )
            );
          },
        ),
      ),
    );
  }
}

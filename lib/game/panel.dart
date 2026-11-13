import 'package:flutter/material.dart';
import 'package:panel_puzzle/sprite/sprite.dart';
import 'package:panel_puzzle/sprite/sprite_animation.dart';

enum GridType{
  Play,
  Target;
}

mixin GirdLayout on PanelGrid{
  GridType? type;
  int _gridSize = 4;
  late List<List<int>> board;

}

extension PanelController on SpriteAnimationController{
  void playOnceViaCallback(String name, void Function() callback){

  }

  void playLoopedViaCallback(String name, void Function() callback){

  }
}

class PanelGrid extends StatefulWidget{
  const new({super.key});

  @override
  State<StatefulWidget> createState() => PanelGridState();
}

class PanelGridState extends State<PanelGrid> {

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    throw UnimplementedError();
  }

}

class _Panel extends StatefulWidget {
  const new({super.key});

  @override
  State<_Panel> createState() => _PanelState();
}

class _PanelState extends State<_Panel> {
  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
import 'package:flutter/material.dart';

class SpriteFrameCollection {
  final List<SpriteFrame> _frames = [];

  SpriteFrameCollection();

  int get numOfFrames => _frames.length;
  List<int> get indices  => List.generate(_frames.length, (index) => index);

  void addFrame(SpriteFrame frame){
    if(!_frames.any((f) => f.name == frame.name)){
      _frames.add(frame);
    }
  }

  void removeFrame({int? index}){
    if(index == null) return;
    _frames.removeAt(index);
  }

  SpriteFrame operator [](int index){
    return _frames[index];
  }

}

class SpriteFrame{
  final String name;
  final Rect rect;
  final Size? frameSize;
  final Offset offset;
  final bool isRotated;

  const SpriteFrame({
    required this.name,
    required this.rect,
    this.frameSize,
    this.offset = Offset.zero,
    this.isRotated = false
  });
}
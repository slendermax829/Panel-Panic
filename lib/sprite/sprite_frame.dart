import 'package:flutter/material.dart';

class SpriteFrameCollection {
  final List<SpriteFrame> _frames = [];

  SpriteFrameCollection();

  int get numOfFrames => _frames.length;
  List<int> get indices  => List.generate(_frames.length, (index) => index);

  void addFrame(SpriteFrame frame){
    if(!_frames.any((f) => f.textureName == frame.textureName)){
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

  List<SpriteFrame> getFramesByPrefix(String prefix){
    final frames = <SpriteFrame>[];
    
    for(var frame in _frames){
      if(frame.name == prefix){
        frames.add(frame);
      }
    }

    frames.sort((a, b) => a.frameNumber.compareTo(b.frameNumber));
    return frames;
  }

}

class SpriteFrame{
  static final RegExp _reg = RegExp(r'^(.+?)\s*(\d+)$');

  final String textureName;
  final Rect rect;
  final Size? frameSize;
  final Offset offset;
  final bool isRotated;

  const SpriteFrame({
    required this.textureName,
    required this.rect,
    this.frameSize,
    this.offset = Offset.zero,
    this.isRotated = false
  });

  String get name{
    Match? match = _reg.firstMatch(textureName.trim());
    if (match == null) {
      throw FormatException('Sprite frame has no numeric suffix: $textureName');
    }
    return match.group(1)!.trimRight();
  }

  int get frameNumber{
    Match? match = _reg.firstMatch(textureName.trim());
    if (match == null) {
      throw FormatException('Sprite frame has no numeric suffix: $textureName');
    }
    return int.parse(match.group(2)!);
  }

  int get frameIndex => frameNumber;
}
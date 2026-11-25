import 'package:flutter/material.dart';

class SpriteFrame{
  static final RegExp _reg = RegExp(r'^(.+?)\s*(\d{4})$|^(.+?)\s*(\d+)$');

  static Match? _frameMatch(String name) => _reg.firstMatch(name.trim());

  static String _prefix(Match match) => (match.group(1) ?? match.group(3)!).trimRight();

  static int _number(Match match) => int.parse(match.group(2) ?? match.group(4)!);

  final String textureName;
  final Rect srcRect;
  final Offset trimOffset;
  final Size originalSize;

  const SpriteFrame({
    required this.textureName,
    required this.srcRect,
    required this.trimOffset,
    required this.originalSize
  });

  ({double width, double height}) get frameSizes => (width: originalSize.width, height: originalSize.height);

  String get frameName{
    final match = _frameMatch(textureName);
    if(match ==  null){
      throw FormatException('Sprite frame has no numeric suffix: $textureName');
    }

    return _prefix(match);
  }

  int get frameNumber{
    final match = _frameMatch(textureName);
    if(match == null){
      throw FormatException('Sprite frame has no numeric suffix: $textureName');
    }

    return _number(match);
  }
}

class SpriteFrameCollection{
  final List<SpriteFrame> _frames = [];

  SpriteFrameCollection();

  int get numOfFrames => _frames.length;
  List<int> get indices => List.generate(_frames.length, (index) => index);

  void addFrame(SpriteFrame frame){
    if(!_frames.any((f) => f.textureName == frame.textureName,)){
      _frames.add(frame);
    }
  }

  void removeFrame({int? index}){
    if(index == null) return;
    _frames.removeAt(index);
  }

  SpriteFrame operator [](int index) => _frames[index];

  List<SpriteFrame> getFramesByPrefix({String? prefix}){
    if(prefix == null) return [];

    final prefixFrames = <SpriteFrame>[];

    for(var frame in _frames){
      final match = SpriteFrame._frameMatch(frame.textureName);
      if(match != null && SpriteFrame._prefix(match) == prefix){
        prefixFrames.add(frame);
      }
    }
    return prefixFrames..sort((a,b) => a.frameNumber.compareTo(b.frameNumber));
  }

  SpriteFrame? getFrame({required String prefix , required int index}){
  
    final name = '$prefix${index.toString().padLeft(4, '0')}';
    
    try {
      final frame = _frames.firstWhere((frame) => frame.frameName == name);
      return frame;
    } on Exception catch (e) {
      return null;
    }
  }

  SpriteFrame? getFrameByName({required String frameName}){
    for (final frame in _frames) {
      if (frame.textureName == frameName) return frame;
    }
    return null;
  }
}
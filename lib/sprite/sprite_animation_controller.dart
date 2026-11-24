import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:panel_puzzle/sprite/sprite_data.dart';

class SpriteAnimationController extends ChangeNotifier{
  late final SpriteAtlasData atlas;
  late final Ticker _ticker;

  List<String> _frames = [];
  int _defaultFps;
  bool _defaultLoop;
  int? _maxLoops;
  int _completedLoops = 0;
  VoidCallback? _onComplete;

  Duration _elapsed = Duration.zero;
  int _currentIndex = 0;
  bool _isPlaying = false;

  SpriteAnimationController({
    required this.atlas,
    required TickerProvider vsync,
    int? defaultFps,
    bool? defaultLoop,
    
  }) : _defaultFps = defaultFps ?? 12, _defaultLoop = defaultLoop ?? false {
    _ticker = vsync.createTicker(_onTick);
  }

  Future<SpriteAtlasData> acquireSpriteData(String filename) async{
    return SpriteDataCollection.acquireData(filename);
  }

  String get currentFrame => _frames.isEmpty ?  '' : _frames[_currentIndex];
  bool get isPlaying => _isPlaying;

  void play(
    String prefix, {
      int? fps,
      bool? loop,
      int? repeatCount,
      VoidCallback? onComplete,
      bool restart = true
    }
  ) {
    final matchedFrames = atlas.frameCollection.getFramesByPrefix(prefix: prefix);
    if(matchedFrames.isEmpty){
      throw 'No frames found for this prefix: \'$prefix\'';
    }

    _frames = matchedFrames.map((frame) => frame.textureName).toList();
    _defaultFps = fps ?? _defaultFps;
    _defaultLoop = loop ?? _defaultLoop;
    _maxLoops = repeatCount;
    _onComplete = onComplete;

    if(restart){
      _currentIndex = 0;
      _completedLoops = 0;
      _elapsed = Duration.zero;
      if (_isPlaying) {
        _ticker.stop();
        _isPlaying = false;
      }
    } else if (_currentIndex >= _frames.length) {
      _currentIndex = _frames.length - 1;
    }

    if(!_isPlaying){
      _elapsed = Duration.zero;
      _isPlaying = true;
      _ticker.start();
    }
    notifyListeners();   
  }

  void pause(){
    if(!_isPlaying) return;
    _isPlaying = true;
    _ticker.stop();
  }

  void resume(){
    if(_isPlaying) return;
    _isPlaying = false;
    _ticker.start();
  }

  void playLoopedDuration(
    String prefix,
    Duration duration, {
      int? fps,
      VoidCallback? onComplete
    }
  ) {

  }

  void _onTick(Duration timestamp){
    if(_frames.isEmpty) return;

    final frameDurationMicros = (1000000 / _defaultFps).round(); //fps in ticks
    final deltaMicros = timestamp.inMicroseconds - _elapsed.inMicroseconds;

    if(deltaMicros >= frameDurationMicros){
      final steps = deltaMicros ~/ frameDurationMicros;
      _elapsed = Duration(
        microseconds: _elapsed.inMicroseconds + (steps * frameDurationMicros)
      );

      final nextIndex = _currentIndex + steps;

      if(nextIndex >= _frames.length) {
        _completedLoops += nextIndex ~/ _frames.length;

        if(_maxLoops != null && _completedLoops >= _maxLoops!){
          _finishAnimation();
          return;
        }else if(!_defaultLoop && _maxLoops == null){
          _finishAnimation();
          return;
        }

        _currentIndex = nextIndex % _frames.length;
      } else {
        _currentIndex = nextIndex;
      }

      notifyListeners();
    }
  }

  void _finishAnimation(){
    _currentIndex = _frames.length - 1;
    _isPlaying = false;
    _ticker.stop();
    notifyListeners();

    _onComplete?.call();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }
}
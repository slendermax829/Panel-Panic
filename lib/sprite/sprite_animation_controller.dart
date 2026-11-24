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
  Duration _lastTimestamp = Duration.zero;
  Duration _tickerOffset = Duration.zero;
  Duration? _durationLimit;
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
    _startPlayback(
      prefix,
      fps: fps,
      loop: loop,
      repeatCount: repeatCount,
      onComplete: onComplete,
      restart: restart,
    );
  }

  void _startPlayback(
    String prefix, {
    int? fps,
    bool? loop,
    int? repeatCount,
    VoidCallback? onComplete,
    bool restart = true,
    int? frameNumber,
    Duration? duration,
  }) {
    final matchedFrames = atlas.frameCollection.getFramesByPrefix(prefix: prefix);
    if(matchedFrames.isEmpty){
      throw ArgumentError('No frames found for this prefix: \'$prefix\'');
    }
    final startIndex = frameNumber == null
        ? 0
        : matchedFrames.indexWhere((frame) => frame.frameNumber == frameNumber);
    if (startIndex < 0) {
      throw ArgumentError('No frame found for prefix: \'$prefix\', index: $frameNumber');
    }
    final playbackFps = fps ?? _defaultFps;
    if (playbackFps <= 0 || playbackFps > Duration.microsecondsPerSecond) {
      throw ArgumentError.value(playbackFps, 'fps', 'Must be between 1 and 1000000');
    }

    _frames = matchedFrames.map((frame) => frame.textureName).toList();
    _defaultFps = playbackFps;
    _defaultLoop = loop ?? _defaultLoop;
    _maxLoops = repeatCount;
    _onComplete = onComplete;
    _durationLimit = duration;

    if(restart){
      _currentIndex = startIndex;
      _completedLoops = 0;
      _elapsed = Duration.zero;
      _lastTimestamp = Duration.zero;
      _tickerOffset = Duration.zero;
      if (_isPlaying) {
        _ticker.stop();
        _isPlaying = false;
      }
    } else if (_currentIndex >= _frames.length) {
      _currentIndex = _frames.length - 1;
    }

    if(!_isPlaying){
      _tickerOffset = _lastTimestamp;
      _isPlaying = true;
      _ticker.start();
    }
    notifyListeners();   
  }

  void pause(){
    if(!_isPlaying) return;
    _isPlaying = false;
    _ticker.stop();
  }

  void resume(){
    if(_isPlaying || _frames.isEmpty) return;
    _tickerOffset = _lastTimestamp;
    _isPlaying = true;
    _ticker.start();
  }

  /// Loops until [duration] of active playback has elapsed, then holds that frame.
  void playLoopedDuration(
    String prefix,
    Duration duration, {
      int? fps,
      VoidCallback? onComplete
    }
  ) {
    if (duration <= Duration.zero) {
      throw ArgumentError.value(duration, 'duration', 'Must be positive');
    }
    _startPlayback(
      prefix,
      fps: fps,
      loop: true,
      onComplete: onComplete,
      duration: duration,
    );
  }

  /// Starts playback from the numeric atlas suffix using the current FPS and loop settings.
  void setOnFrame(
    String prefix,
    int frameIndex, {
      VoidCallback? onComplete
    }
  ){
    _startPlayback(prefix, frameNumber: frameIndex, onComplete: onComplete);
  }

  void _onTick(Duration timestamp){
    if(_frames.isEmpty) return;

    _lastTimestamp = _tickerOffset + timestamp;
    final durationReached = _durationLimit != null && _lastTimestamp >= _durationLimit!;
    final effectiveTimestamp = durationReached ? _durationLimit! : _lastTimestamp;
    final frameDurationMicros = (1000000 / _defaultFps).round(); //fps in ticks
    final deltaMicros = effectiveTimestamp.inMicroseconds - _elapsed.inMicroseconds;

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

      if (!durationReached) notifyListeners();
    }
    if (durationReached) _finishAnimation(holdCurrentFrame: true);
  }

  void _finishAnimation({bool holdCurrentFrame = false}){
    if (!holdCurrentFrame) _currentIndex = _frames.length - 1;
    _isPlaying = false;
    _ticker.stop();
    _durationLimit = null;
    final onComplete = _onComplete;
    _onComplete = null;
    notifyListeners();

    onComplete?.call();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }
}
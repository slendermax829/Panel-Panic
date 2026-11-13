import 'package:flutter/foundation.dart';
import 'package:panel_puzzle/sprite/sprite_frame.dart';

/// Controls one sprite using explicitly registered atlas frame prefixes.
///
/// Playback may be requested before the sprite finishes loading. Repeating a
/// play request for the active prefix does not restart it; stop it first to
/// replay it or change its playback mode.
class SpriteAnimationController extends ChangeNotifier {
  final Set<String> _prefixes = {};
  SpriteFrameCollection? _frames;
  String? _currentAnimation;
  bool _looping = false;

  SpriteAnimationController({Iterable<String> prefixes = const []}) {
    for (final prefix in prefixes) {
      addAnimation(prefix);
    }
  }

  String? get currentAnimation => _currentAnimation;
  bool get isLooping => _looping;
  Set<String> get prefixes => Set.unmodifiable(_prefixes);

  void addAnimation(String prefix) {
    if (prefix.isEmpty) {
      throw ArgumentError.value(prefix, 'prefix', 'Must not be empty');
    }
    if (_frames != null && _frames!.getFramesByPrefix(prefix).isEmpty) {
      throw ArgumentError.value(prefix, 'prefix', 'No frames match this prefix');
    }
    _prefixes.add(prefix);
  }

  void playOnce(String prefix) => _play(prefix, looping: false);

  void playLooped(String prefix) => _play(prefix, looping: true);

  void _play(String prefix, {required bool looping}) {
    if (!_prefixes.contains(prefix)) {
      throw ArgumentError.value(prefix, 'prefix', 'Animation is not registered');
    }
    if (_currentAnimation == prefix) return;
    _currentAnimation = prefix;
    _looping = looping;
    notifyListeners();
  }

  /// Stops playback and clears the displayed frame.
  void stop() {
    if (_currentAnimation == null) return;
    _currentAnimation = null;
    notifyListeners();
  }

  void attachFrames(SpriteFrameCollection frames) {
    if (_frames != null && !identical(_frames, frames)) {
      throw StateError('A SpriteAnimationController can control only one sprite');
    }
    for (final prefix in _prefixes) {
      if (frames.getFramesByPrefix(prefix).isEmpty) {
        throw StateError('No sprite frames match animation prefix "$prefix"');
      }
    }
    _frames = frames;
  }

  void detachFrames(SpriteFrameCollection frames) {
    if (identical(_frames, frames)) _frames = null;
  }
}

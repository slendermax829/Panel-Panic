import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';

class MusicPlayer {
  static final AudioPlayer _musicPlayer = AudioPlayer();
  static final String filename = 'dire dire docks';

  static Future<void> play() async{
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);

    final assets = manifest.listAssets();

    final musicPath = assets.firstWhere((asset) =>
        asset.startsWith('assets/music/') && asset.endsWith('/$filename.mp3'));

    await _musicPlayer.setAsset(musicPath);
    await _musicPlayer.setVolume(.45);
    await _musicPlayer.setLoopMode(LoopMode.one); // Loop
    await _musicPlayer.play();
  }

  static Future<void> stop() => _musicPlayer.stop();

  static Future<void> dispose() => _musicPlayer.dispose();
}
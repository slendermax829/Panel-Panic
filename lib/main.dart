import 'dart:async';

import 'package:flutter/material.dart';
import 'package:panel_puzzle/game/titleScreen.dart';
import 'package:panel_puzzle/shared/background.dart';
import 'package:panel_puzzle/shared/GameTransition.dart';
import 'package:panel_puzzle/shared/musicplayer.dart';
import 'package:panel_puzzle/sprite/sprite_data.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SpriteDataCollection.loadAll();

  debugPrint('Done loading assets');
  debugPrint('Assets Loaded: ${SpriteDataCollection.numOfAssetsLoaded}/n');

  runApp(const MyApp());
  unawaited(_startMusic());
}

Future<void> _startMusic() async {
  try {
    await MusicPlayer.play();
  } catch (error, stackTrace) {
    FlutterError.reportError(FlutterErrorDetails(
      exception: error,
      stack: stackTrace,
      library: 'music player',
      context: ErrorDescription('while playing background music'),
    ));
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        //colorScheme: .fromSeed(seedColor: Colors.deepPurple),
        scaffoldBackgroundColor: Colors.transparent,
        appBarTheme: AppBarTheme(
          backgroundColor: Color.fromARGB(163, 0, 0, 0),
          foregroundColor: Colors.white,
        ),
        cardTheme: CardThemeData(
          color: Colors.teal,
          shape: BoxBorder.all(color: Colors.white, width: 5)
        ),
        fontFamily: 'GameFonts',
      ),
      builder: (context, child) {
        return Stack(
          fit: StackFit.expand,
          children: [
            const IgnorePointer(child: Background()),
            CirclePulseTransition(child: child ?? const SizedBox.shrink()),
          ],
        );
      },
      home: const Titlescreen(),
      //home: const SpriteDemo()
    );
  }
}

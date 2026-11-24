import 'package:flutter/material.dart';
import 'package:panel_puzzle/game/Board.dart';
import 'package:panel_puzzle/game/game_set.dart';
import 'package:panel_puzzle/shared/sprite_demo.dart';
import 'package:panel_puzzle/sprite/sprite.dart';
import 'package:window_manager/legacy.dart';
import 'package:window_manager/window_manager.dart';

const _RESOLUTION = Size(1080, 1920);

Future<void> main() async {
  // WidgetsFlutterBinding.ensureInitialized();
  // await windowManager.ensureInitialized();

  // WindowOptions windowOptions = const WindowOptions(
  //   size: _RESOLUTION,
  //   minimumSize: _RESOLUTION, 
  //   maximumSize: _RESOLUTION,     // Initial width and height
  //   center: true,                // Center the window on screen
  // );

  // windowManager.waitUntilReadyToShow(windowOptions, () async {
  //   await windowManager.show();
  //   await windowManager.focus();
  // });

  runApp(const MyApp());
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
        colorScheme: .fromSeed(seedColor: Colors.deepPurple),
      ),
      //home: const MyHomePage(),
      home: const SpriteDemo()
    );
  }
}

class TestGrid extends StatefulWidget{
  const TestGrid({super.key});

  @override
  State<StatefulWidget> createState() => _TestGridState();
}

class _TestGridState extends State<TestGrid>{

  @override
  Widget build(BuildContext context) {
    return GameSet();
  }

}

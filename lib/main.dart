import 'package:flutter/material.dart';
import 'package:panel_puzzle/game/Board.dart';
import 'package:panel_puzzle/game/game_set.dart';
import 'package:panel_puzzle/sprite/sprite.dart';
import 'package:panel_puzzle/sprite/sprite_animation.dart';
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
      home: const TestGrid(),
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

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});


  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int index = 0;
  final _spriteController = SpriteAnimationController(
    prefixes: [
      'kirb groove', 
      'kirb hurt',
      'kirb victory'
    ],
  );

  @override
  void initState() {
    super.initState();
    _spriteController.playLooped('kirb groove');
  }

  @override
  void dispose() {
    _spriteController.dispose();
    super.dispose();
  }

  void _toggleSpriteAnimation() {
    // final next = _spriteController.currentAnimation == 'kirb groove'
    //     ? 'kirb hurt'
    //     : 'kirb victory';
    // _spriteController.playLooped(next);
    index = ((index + 1) % _spriteController.prefixes.length).round();
    final nextAnimation = _spriteController.prefixes.elementAt(index);
    _spriteController.playLoopedDelayed(nextAnimation, Duration(milliseconds: 150));
  }

  @override
  Widget build(BuildContext context) {
    // return Center(
    //   child: SpriteWidget.squared(
    //     name: 'Kirb',
    //     size: 200,
    //     fps: 24,
    //     filterQuality: FilterQuality.low,
    //     controller: _spriteController,
    //     onTap: _toggleSpriteAnimation,
    //   )
    // );
    int size = 6;

    return Center(
      child: Container(
        width: 400,
        height: 400,
        padding: EdgeInsets.all(10),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.tealAccent),
        ),
        child: GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: size,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.0
          ),
          itemCount: (size*size), 
          itemBuilder:(context, index) {
            return SpriteWidget.squared(
              name: 'Kirb',
              fps: 24,
              size: 200,
              filterQuality: FilterQuality.medium,
              controller: _spriteController,
              onTap: () => _toggleSpriteAnimation(),
            );
          },
        ),
      ),
    );
  }
}

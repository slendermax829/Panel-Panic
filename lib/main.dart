import 'package:flutter/material.dart';
import 'package:panel_puzzle/sprite/sprite.dart';
import 'package:panel_puzzle/sprite/sprite_animation.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: .fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(),
    );
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
    _spriteController.playLooped(nextAnimation);
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SpriteWidget.squared(
        name: 'Kirb',
        size: 200,
        fps: 60,
        filterQuality: FilterQuality.low,
        controller: _spriteController,
        onTap: _toggleSpriteAnimation,
      )
    );
  }
}

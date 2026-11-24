import 'package:flutter/material.dart';
import 'package:panel_puzzle/sprite/sprite.dart';
import 'package:panel_puzzle/sprite/sprite_animation_controller.dart';
import 'package:panel_puzzle/sprite/sprite_data.dart';

class SpriteDemo extends StatefulWidget {
  final String _filename = 'Kirb';

  const new({super.key,});

  @override
  State<SpriteDemo> createState() => _SpriteDemoState();
}

class _SpriteDemoState extends State<SpriteDemo> with SingleTickerProviderStateMixin{
  SpriteAnimationController? _animController;
  Object? _loadError;

  int index = 0;
  int size = 4;

  static const _testPrefixes = <String>[
    'kirb groove',
    'kirb hurt',
    'kirb victory'
  ];

  @override
  void initState() {
    super.initState();
    _setupSprite();
  }

  @override
  void dispose(){
    _animController?.dispose();
    super.dispose();
  }

  Future<void> _setupSprite() async{
    try {
      final atlas = await SpriteDataCollection.acquireData(widget._filename);
      if(!mounted) return;

      final controller = SpriteAnimationController(
        atlas: atlas,
        vsync: this
      );

      try {
        controller.play(_testPrefixes[index], fps: 24, loop: true);
      } catch (_) {
        controller.dispose();
        rethrow;
      }

      setState(() {
        _animController = controller;
      });
    } catch (error, stackTrace) {
      if (mounted) {
        setState(() {
          _loadError = error;
        });
      } else {
        FlutterError.reportError(FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'sprite demo',
          context: ErrorDescription('while loading the sprite atlas'),
        ));
      }
    }
  }

  void _toggleDisplay() {
    index = ((index + 1) % _testPrefixes.length).round();
    _animController?.play(
      _testPrefixes[index],
      fps: 24,
      loop: true,
    );
  }

  void _switchPrefix(int prefix){
    _animController?.play(
      _testPrefixes[prefix],
      fps: 24,
      loop: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = _animController;
    if (_loadError != null) {
      return Center(child: Text('Error loading sprite: $_loadError'));
    }
    if (controller == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: .spaceEvenly,
          crossAxisAlignment: .center,
          children: [
            Row(
              mainAxisAlignment: .center,
              spacing: 25,
              children: [
                for(int i = 0; i < _testPrefixes.length; i++)
                  ElevatedButton(
                    onPressed: () => _switchPrefix(i), 
                    child: Text(_testPrefixes[i])
                )
              ],
            ),
            Text('Tap on below too'),
            Container(
              width: 400,
              height: 400,
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.tealAccent)
              ),
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: size,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1
                ),
                itemCount: (size*size), 
                itemBuilder:(context, index) {
                  return GestureDetector(
                    onTap: () => _toggleDisplay(),
                    child: AnimatedSprite(
                      controller: controller,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
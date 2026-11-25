import 'package:flutter/material.dart';
import 'package:panel_puzzle/game/game_set.dart';
import 'package:panel_puzzle/shared/GameTransition.dart';
import 'package:panel_puzzle/shared/highscore.dart';
import 'package:panel_puzzle/shared/menuItem.dart';

class Titlescreen extends StatefulWidget {

  const Titlescreen({super.key});

  @override
  State<Titlescreen> createState() => _TitlescreenState();
}

class _TitlescreenState extends State<Titlescreen> {
  static const double _titleScale = 0.6;
  static const double _menuScale = 0.05;

  late Future<int> _highScoreFuture = StreakHighScore.getHighScore();

  void _navigateToScreen(BuildContext context, Offset position, Widget screen) async{
    final navigator = Navigator.of(context);
    
    CirclePulseTransition.of(context).trigger(
      position,
      onMidPoint: () async {
        await navigator.push(PageRouteBuilder<void>(
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
          pageBuilder: (context, animation, secondaryAnimation) => screen,
        ));
        // Reload the high score after returning from a game
        if (mounted) {
          _highScoreFuture = StreakHighScore.getHighScore();
          setState((){});
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leadingWidth: 400,
        leading: FutureBuilder<int>(
          future: _highScoreFuture,
          builder:(context, snapshot) {
            if(snapshot.hasData){
              return Text(
                'Streak HighScore: ${snapshot.data}',
                style: TextStyle(fontSize: 30),
              );
            }else{
              return Text('Streak HighScore: ERROR');
            }
          },
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.all(10),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight > 20 ? constraints.maxHeight - 20 : 0,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    spacing: 5,
                    children: [
                      Image.asset(
                        'assets/images/title.png',
                        scale: _titleScale,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 50),
                      Menuitem(child: Builder(
                          builder: (context) {
                            return InkWell(
                              hoverColor: Colors.transparent,
                              splashColor: Colors.transparent,
                              onTap: () {
                                if(GameSet.scoreStreak > 0) GameSet.scoreStreak = 0;
                                GameSet.gridSize = 3;
                                GameSet.setScrambledMoves();
                                
                                final box = context.findRenderObject()! as RenderBox;
                                final position = box.localToGlobal(box.size.center(Offset.zero)); // gets the card's middle position to render transition
                                _navigateToScreen(context, position, const GameSet.randomMode());
                              },
                              child: Image.asset(
                                'assets/images/random game.png',
                                scale: _menuScale,
                                fit: .contain,
                              )
                            );
                          },
                        )
                      ),
                      Menuitem(child: Builder(
                          builder: (context) {
                            return InkWell(
                              hoverColor: Colors.transparent,
                              onTap: () {
                                debugPrint('Work in Progress');
                                // final box = context.findRenderObject()! as RenderBox;
                                // final position = box.localToGlobal(box.size.center(Offset.zero)); // gets the card's middle position to render transition
                                // _navigateToScreen(context, position, const GameSet.randomMode());
                              },
                              child: Image.asset(
                                'assets/images/custom game.png',
                                scale: _menuScale,
                                fit: .contain,
                              )
                            );
                          },
                        )
                      ),
                      Menuitem(child: Builder(
                          builder: (context) {
                            return InkWell(
                              hoverColor: Colors.transparent,
                              onTap: () {
                                debugPrint('Work in Progress');
                                // final box = context.findRenderObject()! as RenderBox;
                                // final position = box.localToGlobal(box.size.center(Offset.zero)); // gets the card's middle position to render transition
                                // _navigateToScreen(context, position, const GameSet.randomMode());
                              },
                              child: Image.asset(
                                'assets/images/board creation.png',
                                scale: _menuScale,
                                fit: .contain,
                              )
                            );
                          },
                        )
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
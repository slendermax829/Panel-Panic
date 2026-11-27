import 'package:flutter/material.dart';
import 'package:panel_puzzle/custom_board/board_creation_mode.dart';
import 'package:panel_puzzle/custom_board/board_entry.dart';
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
        // Reload the high score after returning from a random game
        if (mounted) {
          _highScoreFuture = StreakHighScore.getHighScore();
          setState((){});
        }
      },
    );
  }

  Future<BoardEntry?> _viewBoards() async {
    return await showGeneralDialog<BoardEntry>(
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      context: context, 
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder:(context, animation, secondaryAnimation) {
        return SafeArea(
          child: Align(
            alignment: .center,
            child: Padding(
              padding: const EdgeInsets.all(15),
              child: Material(
                borderRadius: BorderRadius.circular(12),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: FutureBuilder<List<BoardEntry>>(
                    future: BoardJsonWriter.readAll(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState != ConnectionState.done) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final boards = snapshot.data ?? [];
                      debugPrint('\nLength of Boards: ${boards.length}');
                      if (boards.isEmpty) {
                        return const Center(
                          child: Text(
                            'No boards found',
                            style: TextStyle(
                              fontSize: 25,
                              letterSpacing: 5,
                              decoration: TextDecoration.underline
                            ),
                          )
                        );
                      }

                      return ListView.builder(
                        shrinkWrap: true,
                        itemCount: boards.length,
                        itemBuilder: (context, index) {
                          final board = boards[index];
                          return Card(
                            shape: RoundedRectangleBorder(
                              side: const BorderSide(color: Colors.yellowAccent),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ListTile(
                              leading: const Icon(Icons.border_all_outlined),
                              title: Text(board.name ?? 'Unknown'),
                              subtitle: Text('Author: ${board.authorName ?? 'UNKNOWN'}, Date: ${board.dateFormat}'),
                              trailing: Text('Clear Time: ${board.clearTimeFormat}'),
                              onTap: () => Navigator.of(context).pop(board),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        );
      },
      barrierColor: Colors.black54,
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.95, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOut),
            ),
            alignment: Alignment.topRight,
            child: child,
          ),
        );
      },
    );
  }

  Future<void> _openBoardCreation(Offset position) async {
    final boardType = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        contentPadding: EdgeInsetsGeometry.symmetric(vertical: 30, horizontal: 20),
        title: const Text('Which type of board do you wish to create?'),
        alignment: .center,
        children: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              side: BorderSide(color: Colors.deepPurpleAccent),
              
            ),
            onPressed: () => Navigator.of(context).pop('edit'),
            child: const Text('Edit Existing Board'),
          ),
          SizedBox(height: 10,),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              side: BorderSide(color: Colors.deepPurpleAccent),
              
            ),
            onPressed: () => Navigator.of(context).pop('new'),
            child: const Text('Create New Board'),
          ),
        ],
      ),
    );

    if (!mounted || boardType == null) return;

    switch (boardType) {
      case 'new':
        _navigateToScreen(context, position, BoardCreationMode());
      case 'edit':
        final board = await _viewBoards();

        if (!mounted || board == null) return;
        _navigateToScreen(context, position, BoardCreationMode(entryId: board.id));
    }
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
                                final box = context.findRenderObject()! as RenderBox;
                                final position = box.localToGlobal(box.size.center(Offset.zero)); // gets the card's middle position to render transition
                                _openBoardCreation(position);
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
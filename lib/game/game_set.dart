import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:panel_puzzle/game/board.dart';
import 'package:panel_puzzle/game/titleScreen.dart';
import 'package:panel_puzzle/shared/GameTransition.dart';
import 'package:panel_puzzle/shared/highscore.dart';

enum Mode{
  Random,
  Custom;
}

class GameSet extends StatefulWidget {
  static final Random _rand = Random();

  static int gridSize = 4;
  static int _scrambledMoves = 1;
  static const int _tries = 3;

  static int scoreStreak = 0; // for Random Board Mode only

  static void setScrambledMoves(){
    _scrambledMoves = _rand.nextInt(3) + 1;
  }

  static void _setBoardSize(){
    if(scoreStreak % 5 == 0){
      gridSize++;
    }
  }

  final Mode mode;

  const GameSet.randomMode({
    super.key,
  }) : mode = .Random;

  const GameSet.customMode({
    super.key,
  }) : mode = .Custom;

  @override
  State<GameSet> createState() => _GameSetState();
}

class _GameSetState extends State<GameSet> {
  late List<bool> _initialTargetBoard;
  late List<bool> _initialPlayerBoard;

  late List<bool> _targetBoard;
  late List<bool> _playerBoard;

  late int _moves;
  late int _tries;

  bool _isSolved = false;
  bool _isFailed = false;

  final Set<int> _pendingVictoryPanels = {};
  final Set<int> _pendingFailedPanels = {};
  final Set<int> _failedPanels = {};

  int get _numOfPanels => (GameSet.gridSize * GameSet.gridSize);

  @override
  void initState() {
    _moves = GameSet._scrambledMoves;
    _tries = GameSet._tries;
    _generateNewPuzzle();

    super.initState();
  }

  void _navigateBack() async {
    final bool? confirm = widget.mode == .Custom
        ? true
        : await showDialog<bool>(
            barrierDismissible: false,
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Leave current game?'),
              content: const Text('Are you sure you want to leave this game?\n Your Streak will not be saved'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Leave'),
                ),
              ],
            ),
          );
      
    if(confirm! && mounted){
      final navigator = Navigator.of(context);
    
      CirclePulseTransition.of(context).trigger(
        MediaQuery.sizeOf(context).center(Offset.zero),
        onMidPoint: () {
          navigator.push(PageRouteBuilder<void>(
            transitionDuration: Duration.zero,
            reverseTransitionDuration: Duration.zero,
            pageBuilder: (context, animation, secondaryAnimation) => Titlescreen(),
          ));
        },
      );
    }
  }
  
  void _generateNewPuzzle(){
    final Random rand = Random();
    final List<bool> startingBoard = List.generate(_numOfPanels, (_) => rand.nextBool());

    setState(() {
      _playerBoard = List.from(startingBoard);
      _targetBoard = _setBoardIndices(List.from(startingBoard));
      _initialPlayerBoard = List.from(_playerBoard);
      _initialTargetBoard = List.from(_targetBoard);
      _moves = GameSet._scrambledMoves;
      _tries = GameSet._tries;
      _isSolved = false;
      _isFailed = false;
      _pendingVictoryPanels.clear();
      _pendingFailedPanels.clear();
      _failedPanels.clear();
    });
  }

  List<bool> _setBoardIndices(List<bool> board){
    final Random rand = Random();
    final Set<int> chosenIndices = {};

    while(chosenIndices.length < GameSet._scrambledMoves){
      chosenIndices.add(rand.nextInt(_numOfPanels));
    }

    for(final int index in chosenIndices){
      _applyFlipLogic(board, index);
    }

    return board;
  }

  void _applyFlipLogic(List<bool> board, int index){
    final int centerRow = index ~/ GameSet.gridSize;
    final int centerCol = index % GameSet.gridSize;

    for(int rowOffset = -1; rowOffset <= 1; rowOffset++){
      for(int colOffset = -1; colOffset <= 1; colOffset++){
        final int targetRow = centerRow + rowOffset;
        final int targetCol = centerCol + colOffset;

        if(targetRow >= 0 && targetRow < GameSet.gridSize && targetCol >= 0 && targetCol < GameSet.gridSize){
          final int targetIndex = targetRow * GameSet.gridSize + targetCol;
          board[targetIndex] = !board[targetIndex];
        }
      }
    }
  }

  void _onPlayerTap(int index){
    // Can only tap if game isn't solved and player has moves left and tries left
    if(_isSolved || _moves <= 0 || _tries <= 0) return;

    setState((){
      _applyFlipLogic(_playerBoard, index);
      _moves--;
      _isSolved = listEquals(_playerBoard, _targetBoard);

      if (_isSolved) {
        _pendingVictoryPanels
          ..clear()
          ..addAll(List.generate(_numOfPanels, (index) => index));

      } else if (_moves == 0) {
        _tries--;
        _isFailed = true;
        _failedPanels
          ..clear()
          ..addAll(
            List.generate(_numOfPanels, (index) => index).where(
              (index) => _tries == 0 || _playerBoard[index] != _targetBoard[index],
            ),
          );

        _pendingFailedPanels
          ..clear()
          ..addAll(_failedPanels);
      }
    });
  }

  void _onVictoryComplete(int index) {
    if (!mounted || !_isSolved || !_pendingVictoryPanels.remove(index)) return;
    if (_pendingVictoryPanels.isEmpty) _showWinDialog();
  }

  void _onFailedComplete(int index){
    if (!mounted || !_isFailed || !_pendingFailedPanels.remove(index)) return;
    if (_pendingFailedPanels.isEmpty) {
      if (_tries == 0) {
        _showGameOverDialog();
      } else {
        _tryAgainDialog();
      }
    }
  }

  void _showWinDialog(){
      showDialog(
        context: context, 
        barrierDismissible: false,
        builder:(context) => AlertDialog(
          title: const Text('Congratulations!'),
          content: Text('You solved the puzzle'),
          actions: [
            TextButton(
              onPressed:() {
                final navigator = Navigator.of(context);
    
                CirclePulseTransition.of(context).trigger(
                  MediaQuery.sizeOf(context).center(Offset.zero),
                  onMidPoint: () {
                    GameSet.setScrambledMoves();
                    GameSet._setBoardSize();
                    _generateNewPuzzle();
                    navigator.pop(PageRouteBuilder<void>(
                      transitionDuration: Duration.zero,
                      reverseTransitionDuration: Duration.zero,
                      pageBuilder: (context, animation, secondaryAnimation) => GameSet.randomMode(),
                    ));
                  },
                );
                GameSet.scoreStreak++;
              },
              child: const Text('Next')
            )
          ],
        ),
    );
  }

  void _tryAgainDialog(){
    showDialog(
      context: context, 
      barrierDismissible: false,
      builder:(context) => AlertDialog(
        title: const Text('Try Again'),
        content: Text('Ran out of moves. Tries left $_tries'),
        actions: [
          TextButton(
            onPressed:() {
              Navigator.of(context).pop();
              _resetCurrentPuzzle();
            },
            child: const Text('Try Again')
          )
        ],
      ),
    );
  }

  void _showGameOverDialog() async{
    final savedScore = await StreakHighScore.getHighScore();

    if(GameSet.scoreStreak > savedScore){
      await StreakHighScore.saveHighScore(GameSet.scoreStreak);
    }

    showDialog(
      context: context, 
      barrierDismissible: false,
      builder:(context) => AlertDialog(
        title: const Text('Game Over', textAlign: TextAlign.center,),
        content: Column(
          mainAxisAlignment: .center,
          mainAxisSize: .min,
          children: [
            Text('You ran out of tries!'),
            if (GameSet.scoreStreak > savedScore)
              Text('New HighScore: ${GameSet.scoreStreak}')
          ],
        ),
        actionsAlignment: .center,
        actions: [
          TextButton(
            onPressed:() {
              final navigator = Navigator.of(context);
                CirclePulseTransition.of(context).trigger(
                  MediaQuery.sizeOf(context).center(Offset.zero),
                  onMidPoint: () {
                    navigator.pop();
                    navigator.pop();
                  },
                );
            },
            child: const Text('Confirm')
          )
        ],
      ),
    );
  }

  void _resetCurrentPuzzle(){
    setState((){
      _playerBoard = List.from(_initialPlayerBoard);
      _targetBoard = List.from(_initialTargetBoard);
      _moves = GameSet._scrambledMoves;
      _isSolved = false;
      _isFailed = false;
      _pendingFailedPanels.clear();
      _failedPanels.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final mode = widget.mode;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        automaticallyImplyLeading: false, // disable back button from navigation stack
        title: mode == .Random ? Text('Random Game', style: TextStyle(fontFamily: 'GameFonts', fontSize: 36),)
                                : Text('Custom Game', style: TextStyle(fontFamily: 'GameFonts', fontSize: 36)),
        titleTextStyle: TextStyle(
          fontSize: 20,
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.arrow_back_ios),
            tooltip: 'Back to menu',
            onPressed: () => _navigateBack(),
          )
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Column(
                mainAxisAlignment: .spaceEvenly,
                children: [
                  const Text(
                    'TARGET',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 25,
                      letterSpacing: 6,
                      color: Colors.yellowAccent,
                      decoration: TextDecoration.underline,
                      decorationColor: Colors.yellowAccent
                    ),
                  ),
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            mainAxisSize: .min,
                            spacing: 10,
                            children: [
                              const FittedBox(
                                child: Text(
                                  'TRIES',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 25,
                                    letterSpacing: 6,
                                    color: Colors.yellowAccent,
                                    decoration: TextDecoration.underline,
                                    decorationColor: Colors.yellowAccent
                                  ),
                                ),
                              ),
                              ...List.generate(GameSet._tries, (index){
                                final available = index < _tries;
                                return Semantics(
                                  child: Container(
                                    width: 10,
                                    height: 10,
                                    margin: const EdgeInsets.symmetric(vertical: 3),
                                    decoration: BoxDecoration(
                                      color: available ? Colors.green : Colors.red.shade800,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.yellowAccent)
                                    ),
                                  ),
                                );
                              })
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Center(
                            child: AspectRatio(
                              aspectRatio: 1,
                              child: Board(
                                boardSize: GameSet.gridSize,
                                panels: _targetBoard,
                                isInteractive: false,
                                isVictory: _isSolved,
                                onVictoryComplete: _onVictoryComplete,
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Column(
                            mainAxisSize: .min,
                            children: [
                              const FittedBox(
                                child: Text(
                                  'STREAK',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 25,
                                    letterSpacing: 6,
                                    color: Colors.yellowAccent,
                                    decoration: TextDecoration.underline,
                                    decorationColor: Colors.yellowAccent
                                  ),
                                ),
                              ),
                              Text(
                                '${GameSet.scoreStreak}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 25,
                                  letterSpacing: 6,
                                  color: Colors.yellowAccent,
                                ),
                              )
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 15, thickness: 3, indent: 50, endIndent: 50,),
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            mainAxisSize: .min,
                            spacing: 10,
                            children: [
                              const FittedBox(
                                child: Text(
                                  'MOVES',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 25,
                                    letterSpacing: 6,
                                    color: Colors.yellowAccent,
                                    decoration: TextDecoration.underline,
                                    decorationColor: Colors.yellowAccent
                                  ),
                                ),
                              ),
                              FittedBox(
                                child: Text(
                                  '$_moves',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 25,
                                    letterSpacing: 6,
                                    color: Colors.yellowAccent,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Center(
                            child: AspectRatio(
                              aspectRatio: 1,
                              child: Board(
                                boardSize: GameSet.gridSize,
                                panels: _playerBoard,
                                isInteractive: true,
                                onPanelTap: _onPlayerTap,
                                isVictory: _isSolved,
                                failedPanels: _failedPanels,
                                onVictoryComplete: _onVictoryComplete,
                                onFailedComplete: _onFailedComplete,
                              ),
                            ),
                          ),
                        ),
                        const Spacer(),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ]
        )
      ),
    );
  }
}
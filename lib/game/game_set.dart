import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:panel_puzzle/game/board.dart';

enum Mode{
  Random,
  Custom;
}

class GameSet extends StatefulWidget {
  static const int gridSize = 4;
  static const int scrambledMoves = 1;
  static const int _tries = 3;
  static const int scoreStreak = 0; // for Random Board Mode only

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
  final Set<int> _pendingVictoryPanels = {};

  int get _numOfPanels => (GameSet.gridSize * GameSet.gridSize);

  @override
  void initState() {
    _moves = GameSet.scrambledMoves;
    _tries = GameSet._tries;
    _generateNewPuzzle();

    super.initState();
  }
  
  void _generateNewPuzzle(){
    final Random rand = Random();
    final List<bool> startingBoard = List.generate(_numOfPanels, (_) => rand.nextBool());

    setState(() {
      _playerBoard = List.from(startingBoard);
      _targetBoard = _setBoardIndices(List.from(startingBoard));
      _initialPlayerBoard = List.from(_playerBoard);
      _initialTargetBoard = List.from(_targetBoard);
      _moves = GameSet.scrambledMoves;
      _tries = GameSet._tries;
      _isSolved = false;
    });
  }

  List<bool> _setBoardIndices(List<bool> board){
    final Random rand = Random();
    final Set<int> chosenIndices = {};

    while(chosenIndices.length < GameSet.scrambledMoves){
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
      }
    });

    // Check conditions AFTER the move
    if(!_isSolved && _moves == 0){
      if(_tries > 1){
        _tryAgainDialog();
      } else {
        _showGameOverDialog();
      }
    }
  }

  void _onVictoryComplete(int index) {
    if (!mounted || !_isSolved || !_pendingVictoryPanels.remove(index)) return;
    if (_pendingVictoryPanels.isEmpty) _showWinDialog();
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
                Navigator.of(context).pop();
                _generateNewPuzzle();
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
        content: Text('Ran out of tries. Tries left ${_tries-1}'),
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

  void _showGameOverDialog(){
    showDialog(
      context: context, 
      barrierDismissible: false,
      builder:(context) => AlertDialog(
        title: const Text('Game Over'),
        content: Text('You ran out of moves!'),
        actions: [
          TextButton(
            onPressed:() {
              Navigator.of(context).pop();
              _generateNewPuzzle();
            },
            child: const Text('Try Again')
          )
        ],
      ),
    );
  }

  void _resetCurrentPuzzle(){
    final Random rand = Random();
    setState((){
      _playerBoard = List.from(_initialPlayerBoard);
      _targetBoard = List.from(_initialTargetBoard);
      _moves = GameSet.scrambledMoves;
      _tries--;
      _isSolved = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final mode = widget.mode;
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        leading: Column(
          mainAxisSize: .min,
          children: [
            Text('Tries: $_tries', style: const TextStyle(fontSize: 14)),
            Text('Moves: $_moves / ${GameSet.scrambledMoves}', style: const TextStyle(fontSize: 14))
          ],
        ),
        leadingWidth: 100,
        title: mode == .Random
                ? Text('Random Game')
                : Text('Custom Game'),
        titleTextStyle: TextStyle(
          fontSize: 20,
          decoration: TextDecoration.underline
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.menu),
            tooltip: 'Menu',
            onPressed: () => debugPrint('Menu Pressed'),
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
                      letterSpacing: 1.3,
                      color: Colors.yellowAccent,
                      decoration: TextDecoration.underline
                    ),
                  ),
                  Expanded(
                    child: Board(
                      boardSize: GameSet.gridSize, 
                      panels: _targetBoard, 
                      isInteractive: false,
                      isVictory: _isSolved,
                      onVictoryComplete: _onVictoryComplete,
                    ),
                  ),
                  const Divider(height: 15,),
                  Expanded(
                    child: Board(
                      boardSize: GameSet.gridSize, 
                      panels: _playerBoard, 
                      isInteractive: true,
                      onPanelTap: _onPlayerTap,
                      isVictory: _isSolved,
                      onVictoryComplete: _onVictoryComplete,
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
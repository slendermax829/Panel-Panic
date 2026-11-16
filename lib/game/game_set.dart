import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:panel_puzzle/game/board.dart';

class GameSet extends StatefulWidget {
  static const int gridSize = 4;
  static const int scrambledMoves = 1;

  const new({super.key});

  @override
  State<GameSet> createState() => _GameSetState();
}

class _GameSetState extends State<GameSet> {

  late List<bool> _targetBoard;
  late List<bool> _playerBoard;

  late int _moves;
  bool _isSolved = false;

  int get _numOfPanels => (GameSet.gridSize * GameSet.gridSize);

  @override
  void initState() {
    _moves = GameSet.scrambledMoves;
    _generateNewPuzzle();

    super.initState();
  }
  
  void _generateNewPuzzle(){
    final Random rand = Random();
    final List<bool> startingBoard = List.generate(_numOfPanels, (_) => rand.nextBool());

    setState(() {
      _playerBoard = List.from(startingBoard);
      _targetBoard = _setBoardIndices(List.from(startingBoard));
      _moves = GameSet.scrambledMoves;
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
    if(_isSolved || _moves == 0) return;

    setState((){
      _applyFlipLogic(_playerBoard, index);
      _moves--;
      _isSolved = listEquals(_playerBoard, _targetBoard);
    });

    if(_isSolved){
      _showWinDialog();
    } else if(_moves == 0){
      _showGameOverDialog();
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
                Navigator.of(context).pop();
                _generateNewPuzzle();
              },
              child: const Text('Next')
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
      _playerBoard = List.generate(_numOfPanels, (_) => rand.nextBool());
      _targetBoard = _setBoardIndices(List.from(_playerBoard));
      _moves = GameSet.scrambledMoves;
      _isSolved = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.grey,
        foregroundColor: Colors.white,
        title: Text('Moves: $_moves'),
        actions: [
          IconButton(
            icon: const Icon(Icons.replay),
            onPressed: () => _resetCurrentPuzzle(),
          ),
          IconButton(
            onPressed: () => _generateNewPuzzle(),
            icon: const Icon(Icons.shuffle)
          )
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Column(
            mainAxisAlignment: .spaceEvenly,
            children: [
              const Text(
                'TARGET',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.3,
                  color: Colors.indigo
                ),
              ),
              Expanded(
                child: Board(
                  boardSize: GameSet.gridSize, 
                  panels: _targetBoard, 
                  isInteractive: false
                ),
              ),
              const Divider(height: 15,),
              Expanded(
                child: Board(
                  boardSize: GameSet.gridSize, 
                  panels: _playerBoard, 
                  isInteractive: true,
                  onPanelTap: _onPlayerTap,
                ),
              )
            ],
          ),
        )
      ),
    );
  }
}
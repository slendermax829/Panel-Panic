import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:panel_puzzle/custom_board/board_entry.dart';
import 'package:panel_puzzle/game/board.dart';
import 'package:panel_puzzle/game/titleScreen.dart';
import 'package:panel_puzzle/shared/GameTransition.dart';

class CustomGame extends StatefulWidget {
  final BoardEntry board;

  const CustomGame({super.key, required this.board});

  @override
  State<CustomGame> createState() => _CustomGameState();
}

class _CustomGameState extends State<CustomGame> {
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _timer;

  late final int? _gridSize;

  late final List<bool> _startingBoard;
  late final List<bool> _targetBoard;

  late List<bool> _playerBoard;

  Duration? _bestTime;

  late int _moves;

  bool _isSolved = false;
  bool _isFailed = false;

  final Set<int> _pendingVictoryPanels = {};
  final Set<int> _pendingFailedPanels = {};
  final Set<int> _failedPanels = {};

  bool get _validBoard =>
      _gridSize != null &&
      _gridSize > 0 &&
      _startingBoard.length == _gridSize * _gridSize &&
      _targetBoard.length == _startingBoard.length &&
      (_moves > 0 || listEquals(_startingBoard, _targetBoard));

  int get _numOfPanels => (widget.board.gridSize! * widget.board.gridSize!);

  @override
  void initState() {
    super.initState();
    _gridSize = widget.board.gridSize;
    _startingBoard = List.of(widget.board.startBoard ?? []);
    _targetBoard = List.of(widget.board.endBoard ?? []);
    _playerBoard = List.of(_startingBoard);
    _bestTime = widget.board.clearTime;
    _moves = widget.board.steps!.length;
    _startTimer();
    if (_validBoard) _startAttempt();
  }

  void _startTimer() {
    _timer?.cancel();
    _stopwatch
      ..reset()
      ..start();
    _timer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (mounted) setState(() {});
    });
  }

  void _startAttempt() {
    if (listEquals(_playerBoard, _targetBoard)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_isSolved && listEquals(_playerBoard, _targetBoard)) {
          _finishAttempt();
        }
      });
    }
  }

  void _restart() {
    setState(() {
      _moves = widget.board.steps!.length;
      _playerBoard = List.of(_startingBoard);
      _isSolved = false;
      _isFailed = false;
      _pendingVictoryPanels.clear();
      _pendingFailedPanels.clear();
      _failedPanels.clear();
      _startAttempt();
    });
  }

  void _onPlayerTap(int index) {
    if (_isSolved || _isFailed || _moves <= 0) return;
    setState(() {
      _applyFlipLogic(_playerBoard, index);
      _moves--;
      _isSolved = listEquals(_playerBoard, _targetBoard);

      if(_isSolved){
        _stopwatch.stop();
        _timer?.cancel();
        _pendingVictoryPanels
          ..clear()
          ..addAll(List.generate(_numOfPanels, (index) => index));
      }else if (_moves == 0){
        _isFailed = true;
        _failedPanels
          ..clear()
          ..addAll(
            List.generate(_numOfPanels, (index) => index).where(
              (index) => _playerBoard[index] != _targetBoard[index],
            ),
          );
        
        _pendingFailedPanels
          ..clear()
          ..addAll(_failedPanels);
      }   
    });
  }

  void _applyFlipLogic(List<bool> board, int index){
    final int centerRow = index ~/ widget.board.gridSize!;
    final int centerCol = index % widget.board.gridSize!;

    for(int rowOffset = -1; rowOffset <= 1; rowOffset++){
      for(int colOffset = -1; colOffset <= 1; colOffset++){
        final int targetRow = centerRow + rowOffset;
        final int targetCol = centerCol + colOffset;

        if(targetRow >= 0 && targetRow < widget.board.gridSize! && targetCol >= 0 && targetCol < widget.board.gridSize!){
          final int targetIndex = targetRow * widget.board.gridSize! + targetCol;
          board[targetIndex] = !board[targetIndex];
        }
      }
    }
  }

  void _navigateBack() async {
    final confirm = _isSolved ? true : await showDialog<bool>(
            barrierDismissible: false,
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Leave current game?'),
              content: const Text('Are you sure you want to leave this game?\n Your time will not be saved'),
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

  Future<void> _finishAttempt() async {
    _stopwatch.stop();
    _timer?.cancel();
    final time = _stopwatch.elapsed;
    setState(() => _isSolved = true);

    String? saveError;
    try {
      _bestTime = await BoardJsonWriter.recordClearTime(widget.board, time);
    } catch (error) {
      saveError = 'Could not save your best time: $error';
    }
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Congratulations!'),
        content: Column(
          mainAxisAlignment: .center,
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Time: ${BoardEntry.formatTime(time)}'),
            Text('Best: ${_bestTime == null ? 'Not set' : BoardEntry.formatTime(_bestTime!)}'),
            if(_bestTime == null || time.inMilliseconds < _bestTime!.inMilliseconds) const Text('New High Score'),
            if (saveError != null) Text(saveError),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _navigateBack();
            },
            child: const Text('Back to menu'),
          ),
        ],
      ),
    );
  }

  void _onVictoryComplete(int index) {
    if (!mounted || !_isSolved || !_pendingVictoryPanels.remove(index)) return;
    if (_pendingVictoryPanels.isEmpty) _finishAttempt();
  }

  void _onFailedComplete(int index){
    if (!mounted || !_isFailed || !_pendingFailedPanels.remove(index)) return;
    if (_pendingFailedPanels.isEmpty) {
      _restart();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _stopwatch.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: IconButton(
          tooltip: 'Back to Title Screen',
          onPressed: () => _navigateBack(), 
          icon: Icon(Icons.arrow_back_ios)
        ),
        title: Text(
          widget.board.name ?? 'Custom Game',
          style: TextStyle(fontSize: 36),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Restart Puzzle',
            onPressed: _isSolved ? null : _restart, 
            icon: Icon(Icons.restart_alt)
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
                                  boardSize: _gridSize!,
                                  panels: _targetBoard,
                                  isInteractive: false,
                                  isVictory: _isSolved,
                                  failedPanels: _failedPanels,
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
                                    'TIME',
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
                                  BoardEntry.formatTime(_stopwatch.elapsed),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 25,
                                    letterSpacing: 6,
                                    color: Colors.yellowAccent,
                                  ),
                                ),
                                const FittedBox(
                                  child: Text(
                                    'BEST',
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
                                  _bestTime == null ? '99:99:99' : BoardEntry.formatTime(_bestTime!),
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
                      child: Center(
                        child: AspectRatio(
                          aspectRatio: 1,
                          child: Board(
                            boardSize: _gridSize,
                            panels: _playerBoard,
                            isInteractive: !_isSolved && !_isFailed,
                            onPanelTap: _onPlayerTap,
                            isVictory: _isSolved,
                            failedPanels: _failedPanels,
                            onVictoryComplete: _onVictoryComplete,
                            onFailedComplete: _onFailedComplete,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:panel_puzzle/custom_board/custom_board.dart';

enum CustomMode { Design, Puzzle }

class BoardCreationMode extends StatefulWidget {
  const BoardCreationMode({super.key});

  @override
  State<BoardCreationMode> createState() => _BoardCreationModeState();
}

class _BoardCreationModeState extends State<BoardCreationMode> {
  static const int _minGridSize = 3;
  static const int _maxGridSize = 10;

  static final _today = DateTime.now();

  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _boardNameController;
  late final TextEditingController _authorController;
  

  int _gridSize = 3;
  CustomMode _currMode = .Design;

  // Initial layout the player builds in Design mode.
  late List<bool> _designBoard;

  // Working board while recording steps in Puzzle mode.
  late List<bool> _board;

  // Tapped panel indices, in order.
  final List<int> _steps = [];

  String get _dateOnly => DateFormat.yMMMd().format(_today);

  int get _numOfPanels => _gridSize * _gridSize;

  // The panel used in the last step can't be used again until that step is undone.
  int? get _blockedPanel => _steps.isEmpty ? null : _steps.last;

  Color get _modeColor => _currMode == .Puzzle ? Colors.tealAccent : Colors.orangeAccent;

  @override
  void initState() {
    super.initState();
    _boardNameController = TextEditingController();
    _authorController = TextEditingController();

    _designBoard = List.filled(_numOfPanels, false);
    _board = List.from(_designBoard);
  }

  @override
  void dispose() {
    _boardNameController.dispose();
    super.dispose();
  }

  void _showMessanger({String? msg, Color? color}){
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: Duration(seconds: 3),
        backgroundColor: color,
        content: Text(
          msg ?? 'unknown msg',
          style: TextStyle(
            color: Colors.white
          ),
        )
      )
    );
  }

  void _setMode(CustomMode mode) {
    if (mode == _currMode) return;

    setState(() {
      _currMode = mode;
      _steps.clear();
      _board = List.from(_designBoard);
    });
  }

  void _setGridSize(int size) {
    setState(() {
      _gridSize = size;
      _designBoard = List.filled(_numOfPanels, false);
      _board = List.from(_designBoard);
      _steps.clear();
    });
  }

  void _randomizePanels() {
    final Random rand = Random();
    setState(() {
      _designBoard = List.generate(_numOfPanels, (_) => rand.nextBool());
    });
  }

  void _onPanelTap(int index) {
    switch (_currMode) {
      case .Design:
        setState(() => _designBoard[index] = !_designBoard[index]);

      case .Puzzle:
        if (index == _blockedPanel) {
          _showMessanger(msg: 'This panel was used in the previous step. Undo that step to use that panel again.', color: Colors.red);
          return;
        }

        setState(() {
          _applyFlipLogic(_board, index);
          _steps.add(index);
        });
    }
  }

  void _undoStep() {
    if (_steps.isEmpty) return;

    setState(() {
      // Flipping is its own inverse, so re-applying the last step reverts it.
      _applyFlipLogic(_board, _steps.removeLast());
    });
  }

  void _resetBoard() {
    setState(() {
      _steps.clear();
      if (_currMode == .Design) {
        _designBoard = List.filled(_numOfPanels, false);
      }
      _board = List.from(_designBoard);
    });
  }

  void _applyFlipLogic(List<bool> board, int index) {
    final int centerRow = index ~/ _gridSize;
    final int centerCol = index % _gridSize;

    for (int rowOffset = -1; rowOffset <= 1; rowOffset++) {
      for (int colOffset = -1; colOffset <= 1; colOffset++) {
        final int targetRow = centerRow + rowOffset;
        final int targetCol = centerCol + colOffset;

        if (targetRow >= 0 &&
            targetRow < _gridSize &&
            targetCol >= 0 &&
            targetCol < _gridSize) {
          final int targetIndex = targetRow * _gridSize + targetCol;
          board[targetIndex] = !board[targetIndex];
        }
      }
    }
  }

  String _stepLabel(int index) =>
      'Row ${index ~/ _gridSize + 1}, Col ${index % _gridSize + 1}';

  @override
  Widget build(BuildContext context) {
    final bool isDesign = _currMode == .Design;

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back_ios),
        ),
        title: const Text(
          'Custom Board Creation',
          style: TextStyle(fontFamily: 'GameFonts', fontSize: 36),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_document),
            tooltip: 'Edit Board',
            onPressed: () => _scaffoldKey.currentState?.openDrawer(),
          ),
          IconButton(
            icon: const Icon(Icons.format_list_numbered),
            tooltip: 'Puzzle Steps',
            onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Reset Board',
        child: const Icon(Icons.restart_alt),
        onPressed: _resetBoard,
      ),
      drawer: Drawer(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: .start,
              spacing: 16,
              children: [
                const Text(
                  'Board Configuration',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                Text('Date: $_dateOnly', style: TextStyle(fontSize: 16),),
                const Divider(height: 1),
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: .start,
                    spacing: 15,
                    children: [
                      TextFormField(
                        controller: _boardNameController,
                        decoration: const InputDecoration(
                          icon: Icon(Icons.edit),
                          labelText: 'Board name',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if(value == null || value.isEmpty){
                            return 'A name must be filled out';
                          }
                          return null;
                        },
                      ),
                      TextFormField(
                        controller: _authorController,
                        decoration: const InputDecoration(
                          icon: Icon(Icons.book),
                          labelText: 'Author',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if(value == null || value.isEmpty){
                            return 'A author for this board must filled out';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                Text('Grid size: $_gridSize x $_gridSize', style: TextStyle(fontSize: 18),),
                Slider(
                  value: _gridSize.toDouble(),
                  min: _minGridSize.toDouble(),
                  max: _maxGridSize.toDouble(),
                  divisions: _maxGridSize - _minGridSize,
                  label: '$_gridSize',
                  onChanged: isDesign
                      ? (value) => _setGridSize(value.round())
                      : null,
                ),
                OutlinedButton.icon(
                  onPressed: isDesign ? _randomizePanels : null,
                  icon: const Icon(Icons.shuffle),
                  label: const Text('Randomize layout'),
                ),
                if (!isDesign)
                  const Text('Switch to Design mode to change the layout.'),
              ],
            ),
          ),
        ),
      ),
      endDrawer: Drawer(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: .start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Puzzle Steps (${_steps.length})',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: _steps.isEmpty
                    ? const Center(child: Text('No steps yet'))
                    : ListView.builder(
                        itemCount: _steps.length,
                        itemBuilder: (context, i) => ListTile(
                          leading: CircleAvatar(child: Text('${i + 1}')),
                          title: Text(_stepLabel(_steps[i])),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Column(
            mainAxisAlignment: .spaceEvenly,
            children: [
              Text(
                _currMode.name.toUpperCase(),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 25,
                  letterSpacing: 7,
                  color: _modeColor,
                  decoration: TextDecoration.underline,
                  decorationColor: _modeColor,
                ),
              ),
              SegmentedButton<CustomMode>(
                segments: const [
                  ButtonSegment(
                    value: CustomMode.Design,
                    icon: Icon(Icons.grid_on),
                    label: Text('Layout'),
                  ),
                  ButtonSegment(
                    value: CustomMode.Puzzle,
                    icon: Icon(Icons.touch_app),
                    label: Text('Steps'),
                  ),
                ],
                selected: {_currMode},
                onSelectionChanged: (selection) => _setMode(selection.first),
              ),
              Expanded(
                child: Transform.scale(
                  scale: .75,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(14.0),
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: CustomBoard(
                          boardSize: _gridSize,
                          panels: isDesign ? _designBoard : _board,
                          mode: _currMode,
                          onPanelTap: _onPanelTap,
                          blockedPanel: _blockedPanel,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (isDesign)
                Text(
                  'Tap panels to set the initial layout',
                  style: TextStyle(
                    fontSize: 20,
                    color: _modeColor
                  ),
                )
              else
                Row(
                  mainAxisAlignment: .center,
                  spacing: 16,
                  children: [
                    Text(
                      'Steps: ${_steps.length}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _modeColor,
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: _steps.isEmpty ? null : _undoStep,
                      icon: const Icon(Icons.undo, color: Colors.amberAccent,),
                      label: const Text('Undo', style: TextStyle(color: Colors.amberAccent),),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

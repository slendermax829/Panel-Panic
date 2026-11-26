import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

class BoardEntry {
  // Unique per entry so it can be updated or deleted later.
  final int id;

  final String name;
  final String authorName;

  final int gridSize;

  final List<bool> startBoard;
  final List<bool> endBoard;

  final Duration? clearTime;
  final DateTime date;

  BoardEntry({
    int? id,
    required this.name,
    required this.authorName,
    required this.gridSize,
    required List<bool> startBoard,
    required List<bool> endBoard,
    this.clearTime,
    DateTime? date,
  })  : date = date ?? DateTime.now(),
        id = id ?? DateTime.now().microsecondsSinceEpoch.toInt(),
        startBoard = List.unmodifiable(startBoard),
        endBoard = List.unmodifiable(endBoard);

  factory BoardEntry.fromJson(Map<String, dynamic> json) {
    final clearTime = json['clearTimeMs'] as int?;

    return BoardEntry(
      id: json['id'] as int,
      name: json['name'] as String,
      authorName: json['authorName'] as String,
      gridSize: json['gridSize'] as int,
      startBoard: (json['startBoard'] as List).cast<bool>(),
      endBoard: (json['endBoard'] as List).cast<bool>(),
      clearTime: clearTime == null ? null : Duration(milliseconds: clearTime),
      date: DateTime.parse(json['date'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'authorName': authorName,
        'gridSize': gridSize,
        'startBoard': startBoard,
        'endBoard': endBoard,
        'clearTimeMs': clearTime?.inMilliseconds,
        'date': date.toIso8601String(),
      };
}

/// Stores every custom board in one JSON file:
/// `{"version": 1, "boards": [ ... ]}`
class BoardJsonWriter {
  static const _fileName = 'custom_boards';
  static const _version = 1;
  static const _encoder = JsonEncoder.withIndent('   ');

  // Serializes read-modify-write cycles so quick successive saves can't overwrite each other.
  static Future<void> _queue = Future.value();

  static Future<File> _getFile(String fileName) async {
    final dir = await getApplicationDocumentsDirectory();

    return File('${dir.path}/$fileName.json');
  }

  static Future<void> _createFile() async {
    final file = await _getFile(_fileName);
    
    await file.create(recursive: true);
  }

  static Future<T> _synchronized<T>(Future<T> Function() action) {
    final result = _queue.then((_) => action());
    _queue = result.then<void>((_) {}, onError: (_) {});
    return result;
  }

  static Future<List<BoardEntry>> _read() async {
    final file = await _getFile(_fileName);
    if (!await file.exists()) return [];

    try {
      final json = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      return (json['boards'] as List)
          .map((board) => BoardEntry.fromJson(board as Map<String, dynamic>))
          .toList();
    } on Object {
      // Keep the unreadable file around instead of overwriting it with an empty list.
      await file.rename('${file.path}.corrupt');
      return [];
    }
  }

  static Future<void> _write(List<BoardEntry> boards) async {
    final file = await _getFile(_fileName);
    final data = {
      'version': _version,
      'boards': boards.map((board) => board.toJson()).toList(),
    };

    // Write to a temp file first so a crash mid-write can't corrupt the saved boards.
    final temp = File('${file.path}.tmp');

    await temp.writeAsString(_encoder.convert(data), flush: true);
    await temp.rename(file.path);
  }

  static Future<List<BoardEntry>> readAll() => _synchronized(_read);

  static Future<BoardEntry?> get(String id) async {
    final boards = await readAll();
    return boards.where((board) => board.id == id).firstOrNull;
  }

  /// Appends [entry], or replaces the stored entry with the same id.
  static Future<void> save(BoardEntry entry) => _synchronized(() async {
        final boards = await _read();
        final index = boards.indexWhere((board) => board.id == entry.id);

        if (index == -1) {
          boards.add(entry);
        } else {
          boards[index] = entry;
        }
        await _write(boards);
      });

  static Future<void> remove(String id) => _synchronized(() async {
        final boards = await _read();
        boards.removeWhere((board) => board.id == id);
        await _write(boards);
      });

  static Future<void> delete() => _synchronized(() async {
        final file = await _getFile(_fileName);

        if (await file.exists()) await file.delete();
      });

  static Future<bool> doesExist() async {
    try {
      final file = await _getFile(_fileName);
      final response = await file.exists();
      
      if(response == false) await _createFile();

      return response;

    }catch(e){
      return false;
    }
  }
}

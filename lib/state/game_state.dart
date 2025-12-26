import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/board_model.dart';
import '../models/game_record.dart';
import '../logic/sudoku_generator.dart';
import '../logic/sudoku_solver.dart';

enum GameStatus { playing, won, lost }

class GameMove {
  final int row;
  final int col;
  final int? previousValue;
  final int? newValue;
  final List<int> previousNotes;
  final List<({int r, int c, int val})> autoRemovedNotes;

  GameMove({
    required this.row,
    required this.col,
    this.previousValue,
    this.newValue,
    required this.previousNotes,
    required this.autoRemovedNotes,
  });
}

class GameController extends ChangeNotifier {
  SudokuBoard? board;
  SudokuBoard? solution;
  ({int row, int col})? selectedCell;
  bool isNoteMode = false;
  int difficulty = 40;
  DateTime? startTime;
  Timer? timer;
  String timeString = "00:00";
  GameStatus status = GameStatus.playing;
  static const String _prefsKey = 'sudoku_save';

  Set<int> completedNumbers = {};
  Set<int> completedRows = {};
  Set<int> completedCols = {};

  // Advanced Features
  int mistakes = 0;
  static const int maxMistakes = 3;
  final List<GameMove> _undoStack = [];
  bool get canUndo => _undoStack.isNotEmpty;

  final _effectController = StreamController<List<int>>.broadcast();
  Stream<List<int>> get effectStream => _effectController.stream;

  GameController() {
    // No auto-init
  }

  void startNewGame({int? difficultyLevel}) {
    if (difficultyLevel != null) difficulty = difficultyLevel;

    final result = SudokuGenerator.generateBoard(emptyCells: difficulty);
    board = result.puzzle;
    solution = result.solution;

    status = GameStatus.playing;
    selectedCell = null;
    isNoteMode = false;
    mistakes = 0;
    _undoStack.clear();
    completedRows.clear();
    completedCols.clear();

    _calculateCompletedNumbers();
    _startTimer();
    saveGame();
    notifyListeners();
  }

  void _startTimer() {
    timer?.cancel();
    startTime ??= DateTime.now();
    timeString = "00:00";

    final now = DateTime.now();
    final diff = now.difference(startTime!);
    final minutes = diff.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = diff.inSeconds.remainder(60).toString().padLeft(2, '0');
    timeString = "$minutes:$seconds";

    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (status != GameStatus.playing) {
        timer.cancel();
        return;
      }
      final now = DateTime.now();
      final diff = now.difference(startTime!);
      final minutes = diff.inMinutes.remainder(60).toString().padLeft(2, '0');
      final seconds = diff.inSeconds.remainder(60).toString().padLeft(2, '0');
      timeString = "$minutes:$seconds";
      notifyListeners();
    });
  }

  void selectCell(int row, int col) {
    if (status != GameStatus.playing) return;
    selectedCell = (row: row, col: col);
    notifyListeners();
  }

  void inputNumber(int number) {
    if (status != GameStatus.playing) return;
    if (selectedCell == null || board == null) return;

    final r = selectedCell!.row;
    final c = selectedCell!.col;
    final cell = board!.grid[r][c];

    if (cell.isFixed || cell.isReadOnly) return;

    // Capture state for undo
    int? prevVal = cell.value;
    List<int> prevNotes = List.from(cell.notes);
    List<({int r, int c, int val})> removedNotes = [];

    if (isNoteMode) {
      // Note input logic
      if (cell.notes.contains(number)) {
        cell.notes.remove(number);
      } else {
        cell.notes.add(number);
      }
      // Note specific move record
      _recordMove(r, c, prevVal, prevVal, prevNotes, removedNotes);
    } else {
      // Value input logic
      if (cell.value == number) return; // No change

      cell.value = number;
      cell.notes.clear();

      bool isCorrect = false;
      if (solution != null) {
        final correctVal = solution!.grid[r][c].value;
        if (number == correctVal) {
          cell.isReadOnly = true;
          cell.isError = false;
          isCorrect = true;
          _checkLineCompletion(r, c);

          // Auto-remove notes
          removedNotes = _autoRemoveNotes(r, c, number);
        } else {
          cell.isError = true;
          mistakes++;
          if (mistakes >= maxMistakes) {
            status = GameStatus.lost;
            saveGame(); // Save the lost state
          }
        }
      } else {
        _validateMove(r, c, number);
      }

      _recordMove(r, c, prevVal, number, prevNotes, removedNotes);
      _calculateCompletedNumbers();

      if (!_hasEmptyCells()) {
        _checkCompletion();
      }
    }

    saveGame();
    notifyListeners();
  }

  void clearCell() {
    if (status != GameStatus.playing) return;
    if (selectedCell == null || board == null) return;
    final r = selectedCell!.row;
    final c = selectedCell!.col;
    final cell = board!.grid[r][c];

    if (cell.isFixed || cell.isReadOnly) return;

    // Undo record
    _recordMove(r, c, cell.value, null, List.from(cell.notes), []);

    cell.value = null;
    cell.notes.clear();
    cell.isError = false;
    _calculateCompletedNumbers();
    saveGame();
    notifyListeners();
  }

  void undo() {
    if (_undoStack.isEmpty || status != GameStatus.playing) return;

    final move = _undoStack.removeLast();
    final cell = board!.grid[move.row][move.col];

    // Restore cell state
    cell.value = move.previousValue;
    cell.notes = List.from(move.previousNotes);
    cell.isError = false; // Reset error state on undo (simplified)
    cell.isReadOnly = false; // Reset lock if it was locked

    // Restore removed notes (reverse auto-remove)
    for (var note in move.autoRemovedNotes) {
      if (!board!.grid[note.r][note.c].isFixed &&
          !board!.grid[note.r][note.c].isReadOnly) {
        board!.grid[note.r][note.c].notes.add(note.val);
        // Sort notes for cleanliness?
        board!.grid[note.r][note.c].notes.sort();
      }
    }

    _calculateCompletedNumbers();
    saveGame();
    notifyListeners();
  }

  void _recordMove(
    int r,
    int c,
    int? prevVal,
    int? newVal,
    List<int> prevNotes,
    List<({int r, int c, int val})> autoRemoved,
  ) {
    _undoStack.add(
      GameMove(
        row: r,
        col: c,
        previousValue: prevVal,
        newValue: newVal,
        previousNotes: prevNotes,
        autoRemovedNotes: autoRemoved,
      ),
    );
  }

  List<({int r, int c, int val})> _autoRemoveNotes(
    int row,
    int col,
    int number,
  ) {
    List<({int r, int c, int val})> removed = [];
    if (board == null) return removed;

    // Helper to remove note from a cell
    void remove(int r, int c) {
      if (r == row && c == col) return; // Skip self (already cleared)
      final cell = board!.grid[r][c];
      if (cell.notes.contains(number)) {
        cell.notes.remove(number);
        removed.add((r: r, c: c, val: number));
      }
    }

    // 1. Row
    for (int c = 0; c < 9; c++) remove(row, c);

    // 2. Col
    for (int r = 0; r < 9; r++) remove(r, col);

    // 3. Box
    int startRow = row - row % 3;
    int startCol = col - col % 3;
    for (int r = startRow; r < startRow + 3; r++) {
      for (int c = startCol; c < startCol + 3; c++) {
        remove(r, c);
      }
    }

    return removed;
  }

  // ... (existing methods: _hasEmptyCells, toggleNoteMode, _validateMove, _checkLineCompletion, _triggerLineEffect, _checkCompletion, _calculateCompletedNumbers) ...
  // Re-pasting shortened validation helper
  void _validateMove(int row, int col, int number) {}

  void _checkLineCompletion(int row, int col) {
    if (!completedRows.contains(row)) {
      bool rowComplete = true;
      for (int c = 0; c < 9; c++) {
        if (board!.grid[row][c].value == null || board!.grid[row][c].isError) {
          rowComplete = false;
          break;
        }
      }
      if (rowComplete) {
        completedRows.add(row);
        _triggerLineEffect(row, true);
      }
    }

    if (!completedCols.contains(col)) {
      bool colComplete = true;
      for (int r = 0; r < 9; r++) {
        if (board!.grid[r][col].value == null || board!.grid[r][col].isError) {
          colComplete = false;
          break;
        }
      }
      if (colComplete) {
        completedCols.add(col);
        _triggerLineEffect(col, false);
      }
    }
  }

  void _triggerLineEffect(int index, bool isRow) {
    List<int> affectedCells = [];
    if (isRow) {
      for (int c = 0; c < 9; c++) affectedCells.add(index * 9 + c);
    } else {
      for (int r = 0; r < 9; r++) affectedCells.add(r * 9 + index);
    }
    _effectController.add(affectedCells);
  }

  void _checkCompletion() {
    if (board == null) return;

    bool errorFree = true;
    for (var row in board!.grid) {
      for (var cell in row) {
        if (cell.isError || cell.value == null) {
          errorFree = false;
          break;
        }
      }
    }

    if (errorFree) {
      timer?.cancel();
      status = GameStatus.won;

      _saveRecord();
      // saveGame() and notifyListeners() will be called by inputNumber
    }
  }

  Future<void> _saveRecord() async {
    if (startTime == null) return;
    final prefs = await SharedPreferences.getInstance();

    // Calculate final duration
    final elapsed = DateTime.now().difference(startTime!).inSeconds;

    final record = GameRecord(
      date: DateTime.now(),
      difficulty: difficulty,
      durationSeconds: elapsed,
      mistakes: mistakes,
    );

    List<String> recordsJson = prefs.getStringList('sudoku_stats') ?? [];
    recordsJson.add(jsonEncode(record.toJson()));
    await prefs.setStringList('sudoku_stats', recordsJson);
  }

  bool _hasEmptyCells() {
    for (var row in board!.grid) {
      for (var cell in row) {
        if (cell.value == null) return true;
      }
    }
    return false;
  }

  void _calculateCompletedNumbers() {
    if (board == null) return;
    final newCompleted = <int>{};
    for (int num = 1; num <= 9; num++) {
      int count = 0;
      for (var row in board!.grid) {
        for (var cell in row) {
          if (cell.value == num && !cell.isError) count++;
        }
      }
      if (count == 9) newCompleted.add(num);
    }
    completedNumbers = newCompleted;
  }

  void toggleNoteMode() {
    isNoteMode = !isNoteMode;
    notifyListeners();
  }

  Future<void> saveGame() async {
    if (board == null) return;
    final prefs = await SharedPreferences.getInstance();

    int elapsed = 0;
    if (startTime != null) {
      elapsed = DateTime.now().difference(startTime!).inSeconds;
    }

    final data = {
      'board': board!.toJson(),
      'solution': solution?.toJson(),
      'difficulty': difficulty,
      'elapsedSeconds': elapsed,
      'status': status.index,
      'mistakes': mistakes, // Save mistakes
    };
    await prefs.setString(_prefsKey, jsonEncode(data));
  }

  Future<bool> loadGame() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey(_prefsKey)) return false;

    try {
      final jsonStr = prefs.getString(_prefsKey);
      final data = jsonDecode(jsonStr!);

      board = SudokuBoard.fromJson(data['board']);
      if (data['solution'] != null) {
        solution = SudokuBoard.fromJson(data['solution']);
      }

      difficulty = data['difficulty'];
      int elapsed = data['elapsedSeconds'];
      status = GameStatus.values[data['status']];
      mistakes = data['mistakes'] ?? 0; // Load mistakes

      startTime = DateTime.now().subtract(Duration(seconds: elapsed));

      completedRows.clear();
      completedCols.clear();

      for (int i = 0; i < 9; i++) {
        // Row check
        bool rowComplete = true;
        for (int c = 0; c < 9; c++) {
          if (board!.grid[i][c].value == null || board!.grid[i][c].isError) {
            rowComplete = false;
            break;
          }
        }
        if (rowComplete) completedRows.add(i);

        // Col check
        bool colComplete = true;
        for (int r = 0; r < 9; r++) {
          if (board!.grid[r][i].value == null || board!.grid[r][i].isError) {
            colComplete = false;
            break;
          }
        }
        if (colComplete) completedCols.add(i);
      }

      _calculateCompletedNumbers();
      _undoStack
          .clear(); // Clear stack on load (persisting stack is hard, so reset)

      if (status == GameStatus.playing) {
        _startTimer();
      }

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint("Error loading game: $e");
      return false;
    }
  }

  Future<bool> hasSavedGame() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey(_prefsKey)) return false;

    try {
      final jsonStr = prefs.getString(_prefsKey);
      final data = jsonDecode(jsonStr!);
      // Only allow continuing if status is playing (0)
      return data['status'] == GameStatus.playing.index;
    } catch (e) {
      return false;
    }
  }

  Future<void> clearSavedGame() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
  }

  @override
  void dispose() {
    timer?.cancel();
    _effectController.close();
    super.dispose();
  }
}

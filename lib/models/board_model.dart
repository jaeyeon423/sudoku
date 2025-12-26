class SudokuCell {
  int? value;
  final bool isFixed; // True if this number was part of the initial puzzle
  bool isReadOnly; // True if user entered correct value
  List<int> notes;
  bool isError; // For visual feedback if the value is invalid

  SudokuCell({
    this.value,
    this.isFixed = false,
    this.isReadOnly = false,
    List<int>? notes,
    this.isError = false,
  }) : notes = notes ?? [];

  /// Creates a deep copy of the cell
  SudokuCell copy() {
    return SudokuCell(
      value: value,
      isFixed: isFixed,
      isReadOnly: isReadOnly,
      notes: List<int>.from(notes),
      isError: isError,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'value': value,
      'isFixed': isFixed,
      'isReadOnly': isReadOnly,
      'notes': notes,
      'isError': isError,
    };
  }

  factory SudokuCell.fromJson(Map<String, dynamic> json) {
    return SudokuCell(
      value: json['value'],
      isFixed: json['isFixed'] ?? false,
      isReadOnly: json['isReadOnly'] ?? false,
      notes: (json['notes'] as List<dynamic>?)?.map((e) => e as int).toList(),
      isError: json['isError'] ?? false,
    );
  }
}

class SudokuBoard {
  final List<List<SudokuCell>> grid;

  SudokuBoard(this.grid);

  /// Creates an empty 9x9 board
  factory SudokuBoard.empty() {
    return SudokuBoard(
      List.generate(9, (_) => List.generate(9, (_) => SudokuCell())),
    );
  }

  /// Creates a deep copy of the board
  SudokuBoard copy() {
    return SudokuBoard(
      grid.map((row) => row.map((cell) => cell.copy()).toList()).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'grid': grid
          .map((row) => row.map((cell) => cell.toJson()).toList())
          .toList(),
    };
  }

  factory SudokuBoard.fromJson(Map<String, dynamic> json) {
    var gridList = json['grid'] as List;
    List<List<SudokuCell>> newGrid = gridList.map((row) {
      return (row as List)
          .map((cellJson) => SudokuCell.fromJson(cellJson))
          .toList();
    }).toList();
    return SudokuBoard(newGrid);
  }
}

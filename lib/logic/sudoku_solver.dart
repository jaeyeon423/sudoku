import '../models/board_model.dart';

class SudokuSolver {
  /// Checks if placing [number] at [row], [col] is valid
  static bool isValid(List<List<int>> grid, int row, int col, int number) {
    // Check row
    for (int x = 0; x < 9; x++) {
      if (grid[row][x] == number) return false;
    }

    // Check column
    for (int x = 0; x < 9; x++) {
      if (grid[x][col] == number) return false;
    }

    // Check 3x3 box
    int startRow = row - row % 3;
    int startCol = col - col % 3;
    for (int i = 0; i < 3; i++) {
      for (int j = 0; j < 3; j++) {
        if (grid[i + startRow][j + startCol] == number) return false;
      }
    }

    return true;
  }

  /// Solves the board using backtracking. Returns true if solvable.
  /// Modifies the [grid] in-place with the solution.
  static bool solve(List<List<int>> grid) {
    for (int row = 0; row < 9; row++) {
      for (int col = 0; col < 9; col++) {
        if (grid[row][col] == 0) {
          for (int number = 1; number <= 9; number++) {
            if (isValid(grid, row, col, number)) {
              grid[row][col] = number;
              if (solve(grid)) {
                return true;
              }
              grid[row][col] = 0; // Backtrack
            }
          }
          return false; // No number works here
        }
      }
    }
    return true; // All cells filled
  }

  /// Checks if the current board state is valid (no duplicates in row/col/box)
  /// Ignores empty cells (0 or null).
  static bool isBoardValid(SudokuBoard board) {
    // We convert to int grid for easier checking, treating null as 0
    List<List<int>> intGrid = List.generate(9, (r) {
      return List.generate(9, (c) {
        return board.grid[r][c].value ?? 0;
      });
    });

    for (int i = 0; i < 9; i++) {
      for (int j = 0; j < 9; j++) {
        int val = intGrid[i][j];
        if (val != 0) {
          // Temporarily remove value to check if it can be placed
          intGrid[i][j] = 0;
          if (!isValid(intGrid, i, j, val)) {
            return false;
          }
          intGrid[i][j] = val; // Put it back
        }
      }
    }
    return true;
  }
}

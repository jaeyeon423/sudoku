import 'package:flutter/material.dart';
import 'dart:async';
import '../state/game_state.dart';
import 'sudoku_cell.dart';

class SudokuGrid extends StatefulWidget {
  final GameController controller;

  const SudokuGrid({super.key, required this.controller});

  @override
  State<SudokuGrid> createState() => _SudokuGridState();
}

class _SudokuGridState extends State<SudokuGrid>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<Color?> _flashAnimation;
  List<int> _flashingCells = [];
  StreamSubscription? _effectSubscription;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _flashAnimation = ColorTween(
      begin: Colors.teal.shade200,
      end: Colors.white,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));

    _effectSubscription = widget.controller.effectStream.listen((cells) {
      setState(() {
        _flashingCells = cells;
      });
      _animController.forward(from: 0).then((_) {
        if (mounted) {
          setState(() {
            _flashingCells = [];
          });
        }
      });
    });

    // Listen for regular updates (repaints)
    widget.controller.addListener(_onControllerUpdate);
  }

  void _onControllerUpdate() {
    setState(() {});
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerUpdate);
    _effectSubscription?.cancel();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black, width: 2),
        ),
        child: GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 9,
          ),
          itemCount: 81,
          itemBuilder: (context, index) {
            int row = index ~/ 9;
            int col = index % 9;
            final cell = widget.controller.board!.grid[row][col];

            bool isSelected = false;
            bool isSameValue = false;
            bool isInRelatedArea = false;
            bool isInCompletedLine = false;

            // Check completed lines
            if (widget.controller.completedRows.contains(row) ||
                widget.controller.completedCols.contains(col)) {
              isInCompletedLine = true;
            }

            if (widget.controller.selectedCell != null) {
              final selectedRow = widget.controller.selectedCell!.row;
              final selectedCol = widget.controller.selectedCell!.col;

              isSelected = (row == selectedRow && col == selectedCol);

              final selectedValue =
                  widget.controller.board!.grid[selectedRow][selectedCol].value;
              if (selectedValue != null && cell.value == selectedValue) {
                isSameValue = true;
              }

              if (!isSelected) {
                if (row == selectedRow || col == selectedCol) {
                  isInRelatedArea = true;
                } else {
                  int startRow = selectedRow - selectedRow % 3;
                  int startCol = selectedCol - selectedCol % 3;
                  if (row >= startRow &&
                      row < startRow + 3 &&
                      col >= startCol &&
                      col < startCol + 3) {
                    isInRelatedArea = true;
                  }
                }
              }
            }

            final bool rightBorder = (col + 1) % 3 == 0 && col != 8;
            final bool bottomBorder = (row + 1) % 3 == 0 && row != 8;

            return AnimatedBuilder(
              animation: _flashAnimation,
              builder: (context, child) {
                Color? flashColor;
                if (_flashingCells.contains(index)) {
                  flashColor = _flashAnimation.value;
                }

                return Container(
                  decoration: BoxDecoration(
                    border: Border(
                      right: BorderSide(
                        color: rightBorder
                            ? Colors.black
                            : Colors.grey.shade300,
                        width: rightBorder ? 2 : 1,
                      ),
                      bottom: BorderSide(
                        color: bottomBorder
                            ? Colors.black
                            : Colors.grey.shade300,
                        width: bottomBorder ? 2 : 1,
                      ),
                    ),
                    color:
                        flashColor ??
                        (isInCompletedLine ? Colors.teal.shade50 : null),
                  ),
                  child: SudokuCellWidget(
                    cell: cell,
                    isSelected: isSelected,
                    isSameValue: isSameValue,
                    isInRelatedArea: isInRelatedArea,
                    onTap: () => widget.controller.selectCell(row, col),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

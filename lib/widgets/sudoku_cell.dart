import 'package:flutter/material.dart';
import '../models/board_model.dart';

class SudokuCellWidget extends StatelessWidget {
  final SudokuCell cell;
  final bool isSelected;
  final bool isSameValue;
  final bool isInRelatedArea;
  final VoidCallback onTap;

  const SudokuCellWidget({
    super.key,
    required this.cell,
    required this.isSelected,
    this.isSameValue = false,
    this.isInRelatedArea = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(color: _getBackgroundColor()),
        child: Center(child: _buildContent()),
      ),
    );
  }

  Color _getBackgroundColor() {
    if (isSelected) return Colors.teal.withOpacity(0.5);
    if (cell.isError) return Colors.red.withOpacity(0.3);
    if (isSameValue)
      return Colors.teal.withOpacity(0.3); // Highlight same numbers
    if (isInRelatedArea)
      return Colors.teal.withOpacity(0.1); // Highlight related row/col/box
    if (cell.isFixed) return Colors.grey.shade200;
    return Colors.white;
  }

  Widget _buildContent() {
    if (cell.value != null) {
      return Text(
        cell.value.toString(),
        style: TextStyle(
          fontSize: 24,
          // Bold if fixed OR same value for emphasis
          fontWeight: (cell.isFixed || isSameValue)
              ? FontWeight.w900
              : FontWeight.normal,
          color: _getTextColor(),
        ),
      );
    } else if (cell.notes.isNotEmpty) {
      return GridView.count(
        crossAxisCount: 3,
        mainAxisSpacing: 0,
        crossAxisSpacing: 0,
        physics: const NeverScrollableScrollPhysics(),
        children: List.generate(9, (index) {
          int num = index + 1;
          return Center(
            child: cell.notes.contains(num)
                ? Text(
                    num.toString(),
                    style: TextStyle(
                      fontSize: 10,
                      color: isSameValue && cell.value == null
                          ? Colors.teal
                          : Colors.grey, // Optional note highlight
                      fontWeight: isSameValue
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  )
                : const SizedBox(),
          );
        }),
      );
    } else {
      return const SizedBox();
    }
  }

  Color _getTextColor() {
    if (cell.isError) return Colors.red;
    if (isSelected) return Colors.white; // Contrast for dark selection
    if (cell.isFixed) return Colors.black;
    return Colors.teal.shade700; // User entered numbers
  }
}

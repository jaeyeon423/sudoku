import 'package:flutter/material.dart';

class NumberPad extends StatelessWidget {
  final Function(int) onNumberPressed;
  final VoidCallback onClearPressed;
  final VoidCallback onNotePressed;
  final VoidCallback? onUndoPressed; // New
  final bool isNoteMode;
  final Set<int> completedNumbers;
  final bool canUndo; // New

  const NumberPad({
    super.key,
    required this.onNumberPressed,
    required this.onClearPressed,
    required this.onNotePressed,
    this.onUndoPressed,
    required this.isNoteMode,
    this.completedNumbers = const {},
    this.canUndo = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildActionButton(
              icon: Icons.undo,
              label: "Undo",
              isActive: false, // Undo isn't a toggle
              isEnabled: canUndo,
              onTap: onUndoPressed ?? () {},
            ),
            _buildActionButton(
              icon: Icons.edit,
              label: "Memo",
              isActive: isNoteMode,
              onTap: onNotePressed,
            ),
            _buildActionButton(
              icon: Icons.delete_outline,
              label: "Clear",
              isActive: false,
              onTap: onClearPressed,
            ),
          ],
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 5,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 1.5,
          ),
          itemCount: 9,
          itemBuilder: (context, index) {
            int num = index + 1;

            if (completedNumbers.contains(num)) {
              return const SizedBox();
            }

            return Visibility(
              visible: !completedNumbers.contains(num),
              maintainSize: true,
              maintainAnimation: true,
              maintainState: true,
              child: ElevatedButton(
                onPressed: () => onNumberPressed(num),
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  backgroundColor: Colors.teal.shade50,
                  foregroundColor: Colors.teal,
                ),
                child: Text(
                  "$num",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
    bool isEnabled = true,
  }) {
    // If not enabled, show lighter color
    final color = isEnabled
        ? (isActive ? Colors.teal : Colors.grey.shade100)
        : Colors.grey.shade50;

    final iconColor = isEnabled
        ? (isActive ? Colors.white : Colors.black87)
        : Colors.grey.shade300;

    final textColor = isEnabled
        ? (isActive ? Colors.white : Colors.black87)
        : Colors.grey.shade300;

    return InkWell(
      onTap: isEnabled ? onTap : null,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 8,
        ), // Adjusted padding
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, color: iconColor),
            Text(label, style: TextStyle(color: textColor, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

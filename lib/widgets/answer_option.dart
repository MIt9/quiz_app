import 'package:flutter/material.dart';

class AnswerOption extends StatelessWidget {
  final int index;
  final String text;
  final bool isSelected;
  final bool isCorrect;
  final bool isWrong;
  final bool enabled;
  final VoidCallback onTap;

  const AnswerOption({
    super.key,
    required this.index,
    required this.text,
    required this.isSelected,
    required this.isCorrect,
    required this.isWrong,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    Color borderColor;
    Color backgroundColor;
    Color textColor = colorScheme.onSurface;

    if (isCorrect) {
      borderColor = Colors.green;
      backgroundColor = Colors.green.withAlpha(25);
      textColor = Colors.green.shade800;
    } else if (isWrong) {
      borderColor = colorScheme.error;
      backgroundColor = colorScheme.error.withAlpha(25);
      textColor = colorScheme.error;
    } else if (isSelected) {
      borderColor = colorScheme.primary;
      backgroundColor = colorScheme.primary.withAlpha(20);
    } else {
      borderColor = colorScheme.outline.withAlpha(100);
      backgroundColor = colorScheme.surface;
    }

    final labels = ['A', 'B', 'C', 'D'];

    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: isCorrect || isWrong ? 2 : 1),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: (isCorrect || isWrong || isSelected) ? borderColor : colorScheme.surfaceContainerHighest,
              ),
              child: Center(
                child: Text(
                  labels[index],
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: (isCorrect || isWrong || isSelected) ? Colors.white : colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: TextStyle(fontSize: 15, color: textColor),
              ),
            ),
            if (isCorrect) const Icon(Icons.check_circle, color: Colors.green),
            if (isWrong) Icon(Icons.cancel, color: colorScheme.error),
          ],
        ),
      ),
    );
  }
}

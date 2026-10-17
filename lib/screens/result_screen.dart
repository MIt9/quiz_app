import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/quiz_provider.dart';

class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final quiz = context.read<QuizProvider>();
    final total = quiz.totalQuestions;
    final correct = quiz.correctCount;
    final incorrect = total - correct;
    final percent = total == 0 ? 0.0 : correct / total;

    final color = percent >= 0.8
        ? Colors.green
        : percent >= 0.5
            ? Colors.orange
            : Theme.of(context).colorScheme.error;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Результат'),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Spacer(),
            _ScoreCircle(percent: percent, color: color, correct: correct, total: total),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _StatChip(label: 'Правильно', value: correct, color: Colors.green),
                const SizedBox(width: 16),
                _StatChip(
                  label: 'Неправильно',
                  value: incorrect,
                  color: Theme.of(context).colorScheme.error,
                ),
              ],
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  quiz.resetToIdle();
                  Navigator.of(context).popUntil((r) => r.isFirst);
                },
                child: const Text('На головну'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  quiz.startQuiz(quiz.questions);
                  Navigator.of(context).pop();
                },
                child: const Text('Пройти знову'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScoreCircle extends StatelessWidget {
  final double percent;
  final Color color;
  final int correct;
  final int total;

  const _ScoreCircle({
    required this.percent,
    required this.color,
    required this.correct,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 160,
          height: 160,
          child: CircularProgressIndicator(
            value: percent,
            strokeWidth: 12,
            color: color,
            backgroundColor: color.withAlpha(40),
          ),
        ),
        Column(
          children: [
            Text(
              '${(percent * 100).round()}%',
              style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: color),
            ),
            Text(
              '$correct / $total',
              style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _StatChip({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Column(
        children: [
          Text(
            value.toString(),
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color),
          ),
          Text(label, style: TextStyle(color: color)),
        ],
      ),
    );
  }
}

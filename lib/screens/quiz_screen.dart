import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/quiz_provider.dart';
import '../providers/tts_provider.dart';
import '../widgets/answer_option.dart';
import 'result_screen.dart';
import 'settings_screen.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  @override
  void dispose() {
    context.read<TtsProvider>().stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<QuizProvider>(
      builder: (context, quiz, _) {
        if (quiz.state == QuizState.finished) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const ResultScreen()),
            );
          });
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final q = quiz.currentQuestion;
        final progress = (quiz.currentIndex + 1) / quiz.totalQuestions;

        return PopScope(
          onPopInvokedWithResult: (_, __) => context.read<TtsProvider>().stop(),
          child: Scaffold(
            appBar: AppBar(
              title: Text('${quiz.currentIndex + 1} / ${quiz.totalQuestions}'),
              centerTitle: true,
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  context.read<TtsProvider>().stop();
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Покинути квіз?'),
                      content: const Text('Поставити на паузу або скинути прогрес?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Залишитись'),
                        ),
                        TextButton(
                          onPressed: () {
                            quiz.pauseQuiz();
                            Navigator.of(context).popUntil((r) => r.isFirst);
                          },
                          child: const Text('На паузу'),
                        ),
                        TextButton(
                          onPressed: () {
                            quiz.resetToIdle();
                            Navigator.of(context).popUntil((r) => r.isFirst);
                          },
                          child: Text(
                            'Скинути',
                            style: TextStyle(color: Theme.of(context).colorScheme.error),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            body: Column(
              children: [
                LinearProgressIndicator(value: progress, minHeight: 4),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        // Question + TTS button
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                q.question,
                                style: const TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.w600, height: 1.4),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Consumer<TtsProvider>(
                              builder: (context, tts, _) => _TtsButton(
                                isPlaying: tts.isPlaying,
                                onTap: () => tts.isPlaying
                                    ? tts.stop()
                                    : tts.speakQuestion(q),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        ...List.generate(q.options.length, (i) {
                          final isSelected = quiz.selectedIndex == i;
                          final isCorrect = quiz.answered && i == q.correctIndex;
                          final isWrong = quiz.answered && isSelected && i != q.correctIndex;

                          return AnswerOption(
                            index: i,
                            text: q.options[i],
                            isSelected: isSelected,
                            isCorrect: isCorrect,
                            isWrong: isWrong,
                            enabled: !quiz.answered,
                            onTap: () => quiz.answer(i),
                          );
                        }),
                        if (quiz.answered && quiz.selectedIndex != q.correctIndex) ...[
                          const SizedBox(height: 20),
                          _ExplanationSection(),
                        ],
                      ],
                    ),
                  ),
                ),
                if (quiz.answered)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () {
                          context.read<TtsProvider>().stop();
                          quiz.next();
                        },
                        child: Text(quiz.isLastQuestion ? 'Завершити' : 'Далі'),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TtsButton extends StatelessWidget {
  final bool isPlaying;
  final VoidCallback onTap;

  const _TtsButton({required this.isPlaying, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        isPlaying ? Icons.stop_circle_outlined : Icons.volume_up_outlined,
        color: isPlaying
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      tooltip: isPlaying ? 'Зупинити' : 'Читати вголос',
      onPressed: onTap,
    );
  }
}

class _ExplanationSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer2<QuizProvider, TtsProvider>(
      builder: (context, quiz, tts, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (quiz.explanation == null && !quiz.loadingExplanation && quiz.explanationError == null)
              OutlinedButton.icon(
                onPressed: quiz.loadExplanation,
                icon: const Icon(Icons.auto_awesome),
                label: const Text('Пояснити відповідь'),
              ),
            if (quiz.loadingExplanation)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 12),
                    Text('Генерую пояснення...'),
                  ],
                ),
              ),
            if (quiz.explanationError != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      quiz.explanationError!,
                      style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: quiz.loadExplanation,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Спробувати знову'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const SettingsScreen()),
                        ),
                        icon: const Icon(Icons.settings),
                        label: const Text('Налаштування'),
                      ),
                    ],
                  ),
                ],
              ),
            if (quiz.explanation != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.auto_awesome,
                            size: 16,
                            color: Theme.of(context).colorScheme.onSecondaryContainer),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Пояснення Gemini',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSecondaryContainer,
                            ),
                          ),
                        ),
                        _TtsButton(
                          isPlaying: tts.isPlaying,
                          onTap: () => tts.isPlaying
                              ? tts.stop()
                              : tts.speakText(quiz.explanation!),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      quiz.explanation!,
                      style: TextStyle(
                        height: 1.5,
                        color: Theme.of(context).colorScheme.onSecondaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

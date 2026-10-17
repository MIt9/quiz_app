import 'question.dart';
import 'session_result.dart';

class InProgressQuiz {
  final List<Question> questions;
  final int currentIndex;
  final int correctCount;
  final List<QuestionResult> results;

  const InProgressQuiz({
    required this.questions,
    required this.currentIndex,
    required this.correctCount,
    required this.results,
  });

  Map<String, dynamic> toJson() => {
        'questions': questions.map((q) => q.toJson()).toList(),
        'currentIndex': currentIndex,
        'correctCount': correctCount,
        'results': results.map((r) => r.toJson()).toList(),
      };

  factory InProgressQuiz.fromJson(Map<String, dynamic> json) => InProgressQuiz(
        questions: (json['questions'] as List)
            .map((q) => Question.fromJson(q as Map<String, dynamic>))
            .toList(),
        currentIndex: json['currentIndex'] as int,
        correctCount: json['correctCount'] as int,
        results: (json['results'] as List)
            .map((r) => QuestionResult.fromJson(r as Map<String, dynamic>))
            .toList(),
      );
}

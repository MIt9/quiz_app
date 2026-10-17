class QuestionResult {
  final String questionId;
  final String questionText;
  final bool isCorrect;
  final int selectedIndex;
  final int correctIndex;

  const QuestionResult({
    required this.questionId,
    required this.questionText,
    required this.isCorrect,
    required this.selectedIndex,
    required this.correctIndex,
  });

  Map<String, dynamic> toJson() => {
        'questionId': questionId,
        'questionText': questionText,
        'isCorrect': isCorrect,
        'selectedIndex': selectedIndex,
        'correctIndex': correctIndex,
      };

  factory QuestionResult.fromJson(Map<String, dynamic> json) => QuestionResult(
        questionId: json['questionId'] as String,
        questionText: json['questionText'] as String,
        isCorrect: json['isCorrect'] as bool,
        selectedIndex: json['selectedIndex'] as int,
        correctIndex: json['correctIndex'] as int,
      );
}

class SessionResult {
  final String id;
  final DateTime date;
  final int totalQuestions;
  final int correctAnswers;
  final List<QuestionResult> questionResults;

  const SessionResult({
    required this.id,
    required this.date,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.questionResults,
  });

  int get incorrectAnswers => totalQuestions - correctAnswers;
  double get scorePercent => totalQuestions == 0 ? 0 : correctAnswers / totalQuestions * 100;

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'totalQuestions': totalQuestions,
        'correctAnswers': correctAnswers,
        'questionResults': questionResults.map((r) => r.toJson()).toList(),
      };

  factory SessionResult.fromJson(Map<String, dynamic> json) => SessionResult(
        id: json['id'] as String,
        date: DateTime.parse(json['date'] as String),
        totalQuestions: json['totalQuestions'] as int,
        correctAnswers: json['correctAnswers'] as int,
        questionResults: (json['questionResults'] as List)
            .map((r) => QuestionResult.fromJson(r as Map<String, dynamic>))
            .toList(),
      );
}

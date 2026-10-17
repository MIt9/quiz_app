import 'dart:convert';

class Question {
  final String id;
  final String question;
  final List<String> options;
  final int correctIndex;

  const Question({
    required this.id,
    required this.question,
    required this.options,
    required this.correctIndex,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final question = json['question'];
    final options = json['options'];
    final correctIndex = json['correct_index'];

    if (id == null || (id is! String && id is! num) || id.toString().isEmpty) {
      throw const FormatException('поле "id" обов\'язкове (рядок або число)');
    }
    if (question is! String || question.trim().isEmpty) {
      throw const FormatException('поле "question" має бути непорожнім рядком');
    }
    if (options is! List ||
        options.length != 4 ||
        options.any((o) => o is! String || o.trim().isEmpty)) {
      throw const FormatException(
          'поле "options" має містити рівно 4 непорожніх рядки');
    }
    if (correctIndex is! int || correctIndex < 0 || correctIndex > 3) {
      throw const FormatException(
          'поле "correct_index" має бути цілим числом від 0 до 3');
    }

    return Question(
      id: id.toString(),
      question: question,
      options: List<String>.from(options),
      correctIndex: correctIndex,
    );
  }

  /// Parses a quiz file: JSON array of questions. Errors name the question.
  static List<Question> parseList(String content) {
    final Object? data;
    try {
      data = jsonDecode(content);
    } on FormatException catch (e) {
      throw FormatException('невалідний JSON: ${e.message}');
    }
    if (data is! List) {
      throw const FormatException('корінь файлу має бути масивом питань');
    }

    final questions = <Question>[];
    final ids = <String>{};
    for (var i = 0; i < data.length; i++) {
      final item = data[i];
      try {
        if (item is! Map<String, dynamic>) {
          throw const FormatException('питання має бути об\'єктом');
        }
        final q = Question.fromJson(item);
        if (!ids.add(q.id)) {
          throw FormatException('дубль id "${q.id}"');
        }
        questions.add(q);
      } on FormatException catch (e) {
        throw FormatException('питання №${i + 1}: ${e.message}');
      }
    }
    return questions;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'question': question,
        'options': options,
        'correct_index': correctIndex,
      };
}

import 'question.dart';

class SavedFile {
  final String name;
  final DateTime savedAt;
  final List<Question> questions;

  int get questionCount => questions.length;

  const SavedFile({
    required this.name,
    required this.savedAt,
    required this.questions,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'savedAt': savedAt.toIso8601String(),
        'questions': questions.map((q) => q.toJson()).toList(),
      };

  factory SavedFile.fromJson(Map<String, dynamic> json) => SavedFile(
        name: json['name'] as String,
        savedAt: DateTime.parse(json['savedAt'] as String),
        questions: (json['questions'] as List)
            .map((q) => Question.fromJson(q as Map<String, dynamic>))
            .toList(),
      );
}

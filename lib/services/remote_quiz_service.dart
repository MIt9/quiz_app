import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/question.dart';

class RemoteQuizInfo {
  final String file;
  final String title;
  final int? questions;

  const RemoteQuizInfo({required this.file, required this.title, this.questions});
}

class RemoteLanguage {
  final String code;
  final String title;
  final List<RemoteQuizInfo> quizzes;

  const RemoteLanguage({required this.code, required this.title, required this.quizzes});
}

/// Loads quizzes from a public repo laid out as `index.json` + `<lang>/<quiz>.json`.
class RemoteQuizService {
  static const defaultBaseUrl =
      'https://raw.githubusercontent.com/MIt9/quiz-library/main';

  final String baseUrl;

  RemoteQuizService(String baseUrl) : baseUrl = baseUrl.trim().replaceAll(RegExp(r'/+$'), '');

  Future<String> fetchIndexRaw() => _get('index.json');

  static List<RemoteLanguage> parseIndex(String raw) {
    final Object? data;
    try {
      data = jsonDecode(raw);
    } on FormatException catch (e) {
      throw FormatException('невалідний index.json: ${e.message}');
    }
    final langs = data is Map ? data['languages'] : null;
    if (langs is! Map) {
      throw const FormatException('index.json: відсутнє поле "languages"');
    }

    return langs.entries.map((e) {
      final lang = e.value;
      final quizzes = lang is Map ? lang['quizzes'] : null;
      if (quizzes is! List) {
        throw FormatException('index.json: мова "${e.key}" без списку "quizzes"');
      }
      return RemoteLanguage(
        code: e.key as String,
        title: (lang as Map)['title'] as String? ?? e.key as String,
        quizzes: quizzes.map((q) {
          if (q is! Map || q['file'] is! String) {
            throw FormatException('index.json: некоректний запис у "${e.key}"');
          }
          return RemoteQuizInfo(
            file: q['file'] as String,
            title: q['title'] as String? ?? q['file'] as String,
            questions: q['questions'] as int?,
          );
        }).toList(),
      );
    }).toList();
  }

  Future<List<Question>> fetchQuiz(String file) async {
    // index.json is remote input: keep the path inside the repo.
    if (file.contains('://') || file.startsWith('/') || file.split('/').contains('..')) {
      throw FormatException('недопустимий шлях "$file"');
    }
    final questions = Question.parseList(await _get(file));
    if (questions.isEmpty) throw const FormatException('Файл не містить питань');
    return questions;
  }

  Future<String> _get(String path) async {
    final base = Uri.tryParse(baseUrl);
    if (base == null || base.scheme != 'https') {
      throw const FormatException('URL бібліотеки має починатися з https://');
    }
    final response =
        await http.get(Uri.parse('$baseUrl/$path')).timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) {
      throw Exception('Не вдалося завантажити $path (HTTP ${response.statusCode})');
    }
    return utf8.decode(response.bodyBytes);
  }
}

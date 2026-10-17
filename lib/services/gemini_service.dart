import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class GeminiService {
  static const _baseUrl = 'https://generativelanguage.googleapis.com/v1beta';

  static String _parseError(int statusCode, String body) {
    try {
      final data = jsonDecode(body) as Map<String, dynamic>;
      final message = (data['error'] as Map<String, dynamic>?)?['message'] as String?;
      if (statusCode == 429) {
        return 'Квоту Gemini вичерпано. Зачекайте або перевірте ліміти у Google AI Studio.';
      }
      if (statusCode == 404 || (message?.contains('no longer available') ?? false)) {
        return 'Модель недоступна або знята з підтримки. '
            'Оберіть іншу в налаштуваннях (оновіть список моделей).';
      }
      if (statusCode == 400) return 'Невірний запит: ${message ?? body}';
      if (statusCode == 401 || statusCode == 403) {
        return 'Невірний або недійсний API ключ.';
      }
      return message ?? 'Помилка $statusCode';
    } on FormatException {
      if (statusCode == 429) {
        return 'Квоту Gemini вичерпано. Зачекайте або перевірте ліміти у Google AI Studio.';
      }
      return 'Помилка $statusCode';
    }
  }

  final String apiKey;
  final String model;

  GeminiService({required this.apiKey, required this.model});

  Future<List<String>> fetchModels() async {
    final uri = Uri.parse('$_baseUrl/models?key=$apiKey');
    final response = await http.get(uri).timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception(_parseError(response.statusCode, response.body));
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final models = data['models'] as List;

    return models
        .where((m) =>
            ((m['supportedGenerationMethods'] as List?) ?? const [])
                .contains('generateContent'))
        .map((m) => m['name'] as String)
        .where((name) => name.contains('gemini'))
        .map((name) => name.replaceFirst('models/', ''))
        .toList();
  }

  Future<String> explainQuestion(String question, String correctAnswer) async {
    final uri = Uri.parse('$_baseUrl/models/$model:generateContent?key=$apiKey');

    final prompt =
        'Питання інтерв\'ю: "$question"\n\nПравильна відповідь: "$correctAnswer"\n\n'
        'Поясни це простими словами, як пояснив би другу без технічного бекграунду. '
        'Використай просту аналогію з реального життя (наприклад, ресторан, магазин, пошта — '
        'що більш природньо підходить до теми). Структура відповіді:\n'
        '1. Одне речення — суть простими словами.\n'
        '2. Аналогія з реального життя (2-3 речення).\n'
        '3. Як це працює технічно (1-2 речення).\n'
        'Відповідай українською мовою. Без зайвого форматування та зірочок.';

    final body = jsonEncode({
      'contents': [
        {
          'parts': [
            {'text': prompt}
          ]
        }
      ],
      'generationConfig': {
        'temperature': 0.4,
        'maxOutputTokens': 1024,
      },
    });

    final response = await http
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: body,
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode != 200) {
      throw Exception(_parseError(response.statusCode, response.body));
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    // Content blocked by safety filters
    final candidates = data['candidates'] as List?;
    if (candidates == null || candidates.isEmpty) {
      throw Exception('Gemini не повернув відповідь (можливо, вміст заблоковано)');
    }

    final content = candidates.first['content'] as Map<String, dynamic>?;
    final parts = content?['parts'] as List?;
    if (parts == null || parts.isEmpty) {
      throw Exception('Порожня відповідь від Gemini');
    }
    return parts.first['text'] as String;
  }
}

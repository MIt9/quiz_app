import 'package:flutter_test/flutter_test.dart';
import 'package:quiz_app/services/remote_quiz_service.dart';

void main() {
  test('parseIndex reads languages and quizzes', () {
    final langs = RemoteQuizService.parseIndex('''
{"version":1,"languages":{"uk":{"title":"Українська","quizzes":[
  {"file":"uk/a.json","title":"A","questions":3},{"file":"uk/b.json"}]}}}''');
    expect(langs.single.title, 'Українська');
    expect(langs.single.quizzes.map((q) => q.title), ['A', 'uk/b.json']);
    expect(langs.single.quizzes.first.questions, 3);
  });

  test('parseIndex rejects malformed index', () {
    for (final raw in ['{', '[]', '{"languages":{"uk":{}}}', '{"languages":{"uk":{"quizzes":[1]}}}']) {
      expect(() => RemoteQuizService.parseIndex(raw), throwsFormatException, reason: raw);
    }
  });

  test('fetchQuiz rejects paths escaping the repo', () {
    final s = RemoteQuizService('https://example.com/repo/');
    for (final p in ['../x.json', '/etc/x', 'https://evil.com/x.json', 'uk/../../x']) {
      expect(s.fetchQuiz(p), throwsFormatException, reason: p);
    }
  });

  test('non-https base url rejected', () {
    expect(RemoteQuizService('http://example.com').fetchIndexRaw(), throwsFormatException);
  });
}

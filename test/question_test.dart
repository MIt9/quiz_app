import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:quiz_app/models/question.dart';

Map<String, dynamic> q({
  Object? id = 1,
  Object? question = 'Q?',
  Object? options = const ['a', 'b', 'c', 'd'],
  Object? correct = 0,
}) =>
    {'id': id, 'question': question, 'options': options, 'correct_index': correct};

String file(List<Map<String, dynamic>> items) => jsonEncode(items);

void main() {
  test('valid file parses, numeric id becomes string', () {
    final r = Question.parseList(file([q(id: 1), q(id: 'x', correct: 3)]));
    expect(r.map((e) => e.id), ['1', 'x']);
    expect(r.last.correctIndex, 3);
  });

  test('rejects bad input', () {
    final bad = {
      'not json': '{',
      'root not array': '{}',
      'missing id': file([q(id: null)]),
      '3 options': file([q(options: ['a', 'b', 'c'])]),
      'empty option': file([q(options: ['a', '', 'c', 'd'])]),
      'index 4': file([q(correct: 4)]),
      'index -1': file([q(correct: -1)]),
      'index not int': file([q(correct: '0')]),
      'empty question': file([q(question: ' ')]),
      'duplicate id': file([q(id: 1), q(id: '1')]),
    };
    bad.forEach((name, content) {
      expect(() => Question.parseList(content), throwsFormatException,
          reason: name);
    });
  });

  test('error names the question number', () {
    expect(
      () => Question.parseList(file([q(), q(id: 2, correct: 9)])),
      throwsA(isA<FormatException>()
          .having((e) => e.message, 'message', contains('№2'))),
    );
  });
}

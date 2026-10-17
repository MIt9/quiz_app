import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/in_progress_quiz.dart';
import '../models/question.dart';
import '../models/session_result.dart';
import '../services/gemini_service.dart';
import '../services/storage_service.dart';

enum QuizState { idle, inProgress, finished }

class QuizProvider extends ChangeNotifier {
  final StorageService storage;

  List<Question> _questions = [];
  int _currentIndex = 0;
  int? _selectedIndex;
  bool _answered = false;
  int _correctCount = 0;
  final List<QuestionResult> _results = [];
  QuizState _state = QuizState.idle;

  String? _explanation;
  bool _loadingExplanation = false;
  String? _explanationError;

  QuizProvider(this.storage);

  List<Question> get questions => _questions;
  int get currentIndex => _currentIndex;
  Question get currentQuestion => _questions[_currentIndex];
  int? get selectedIndex => _selectedIndex;
  bool get answered => _answered;
  int get correctCount => _correctCount;
  QuizState get state => _state;
  String? get explanation => _explanation;
  bool get loadingExplanation => _loadingExplanation;
  String? get explanationError => _explanationError;
  int get totalQuestions => _questions.length;
  bool get isLastQuestion => _currentIndex == _questions.length - 1;

  void startQuiz(List<Question> questions) {
    _questions = List.from(questions)..shuffle();
    _currentIndex = 0;
    _selectedIndex = null;
    _answered = false;
    _correctCount = 0;
    _results.clear();
    _explanation = null;
    _explanationError = null;
    _loadingExplanation = false;
    _state = QuizState.inProgress;
    storage.clearInProgress();
    notifyListeners();
  }

  void resumeQuiz(InProgressQuiz saved) {
    _questions = saved.questions;
    _currentIndex = saved.currentIndex;
    _selectedIndex = null;
    _answered = false;
    _correctCount = saved.correctCount;
    _results.clear();
    _results.addAll(saved.results);
    _explanation = null;
    _explanationError = null;
    _loadingExplanation = false;
    _state = QuizState.inProgress;
    notifyListeners();
  }

  void answer(int index) {
    if (_answered) return;
    _selectedIndex = index;
    _answered = true;

    final isCorrect = index == currentQuestion.correctIndex;
    if (isCorrect) _correctCount++;

    _results.add(QuestionResult(
      questionId: currentQuestion.id,
      questionText: currentQuestion.question,
      isCorrect: isCorrect,
      selectedIndex: index,
      correctIndex: currentQuestion.correctIndex,
    ));

    _explanation = null;
    _explanationError = null;
    _saveProgress();
    notifyListeners();
  }

  void next() {
    if (!_answered) return;

    if (isLastQuestion) {
      _finishQuiz();
    } else {
      _currentIndex++;
      _selectedIndex = null;
      _answered = false;
      _explanation = null;
      _explanationError = null;
      _loadingExplanation = false;
      _saveProgress();
    }
    notifyListeners();
  }

  void pauseQuiz() {
    _saveProgress();
    _state = QuizState.idle;
    notifyListeners();
  }

  void _saveProgress() {
    if (_state != QuizState.inProgress) return;
    storage.saveInProgress(InProgressQuiz(
      questions: _questions,
      currentIndex: _currentIndex,
      correctCount: _correctCount,
      results: List.from(_results),
    ));
  }

  Future<void> _finishQuiz() async {
    _state = QuizState.finished;
    await storage.clearInProgress();
    final session = SessionResult(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      date: DateTime.now(),
      totalQuestions: _questions.length,
      correctAnswers: _correctCount,
      questionResults: List.from(_results),
    );
    await storage.saveSession(session);
    notifyListeners();
  }

  Future<void> loadExplanation() async {
    if (_loadingExplanation) return;

    final apiKey = storage.apiKey;
    final model = storage.selectedModel;

    if (apiKey.isEmpty || model.isEmpty) {
      _explanationError = 'Налаштуйте Gemini API ключ та модель у налаштуваннях';
      notifyListeners();
      return;
    }

    _loadingExplanation = true;
    _explanation = null;
    _explanationError = null;
    notifyListeners();

    final q = currentQuestion;
    final requestIndex = _currentIndex;
    final requestQuestions = _questions;
    bool isCurrent() =>
        identical(_questions, requestQuestions) && _currentIndex == requestIndex;

    try {
      final service = GeminiService(apiKey: apiKey, model: model);
      final result = await service.explainQuestion(
        q.question,
        q.options[q.correctIndex],
      );
      if (isCurrent()) _explanation = result;
    } on TimeoutException {
      if (isCurrent()) {
        _explanationError = 'Час очікування вичерпано. Перевірте з\'єднання.';
      }
    } catch (e) {
      if (isCurrent()) {
        _explanationError = e.toString().replaceFirst('Exception: ', '');
      }
    } finally {
      if (isCurrent()) _loadingExplanation = false;
      notifyListeners();
    }
  }

  void resetToIdle() {
    storage.clearInProgress();
    _state = QuizState.idle;
    _questions = [];
    notifyListeners();
  }
}

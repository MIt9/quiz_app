import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/in_progress_quiz.dart';
import '../models/saved_file.dart';
import '../models/session_result.dart';
import 'remote_quiz_service.dart';

class StorageService {
  static const _keyApiKey = 'gemini_api_key';
  static const _keyModel = 'gemini_model';
  static const _keySessions = 'quiz_sessions';
  static const _keyInProgress = 'quiz_in_progress';
  static const _keyFileHistory = 'file_history';
  static const _keyLibraryUrl = 'library_url';
  static const _keyLibraryIndex = 'library_index';
  static const _keyTtsRate = 'tts_rate';
  static const _keyTtsPitch = 'tts_pitch';
  static const _keyTtsLanguage = 'tts_language';
  static const _maxFileHistory = 10;

  final SharedPreferences _prefs;

  StorageService(this._prefs);

  static Future<StorageService> create() async {
    final prefs = await SharedPreferences.getInstance();
    return StorageService(prefs);
  }

  // --- Settings ---

  String get apiKey => _prefs.getString(_keyApiKey) ?? '';
  String get selectedModel => _prefs.getString(_keyModel) ?? '';

  Future<void> saveApiKey(String key) => _prefs.setString(_keyApiKey, key);
  Future<void> saveSelectedModel(String model) => _prefs.setString(_keyModel, model);

  // --- Quiz library ---

  String get libraryUrl =>
      _prefs.getString(_keyLibraryUrl) ?? RemoteQuizService.defaultBaseUrl;
  String? get libraryIndexCache => _prefs.getString(_keyLibraryIndex);

  Future<void> saveLibraryUrl(String url) async {
    await _prefs.setString(_keyLibraryUrl, url);
    await _prefs.remove(_keyLibraryIndex);
  }

  Future<void> saveLibraryIndexCache(String raw) =>
      _prefs.setString(_keyLibraryIndex, raw);

  // --- TTS settings ---

  double get ttsRate => _prefs.getDouble(_keyTtsRate) ?? 0.45;
  double get ttsPitch => _prefs.getDouble(_keyTtsPitch) ?? 1.0;
  String get ttsLanguage => _prefs.getString(_keyTtsLanguage) ?? 'uk-UA';

  Future<void> saveTtsRate(double v) => _prefs.setDouble(_keyTtsRate, v);
  Future<void> saveTtsPitch(double v) => _prefs.setDouble(_keyTtsPitch, v);
  Future<void> saveTtsLanguage(String v) => _prefs.setString(_keyTtsLanguage, v);

  // --- Sessions ---

  List<SessionResult> loadSessions() {
    final raw = _prefs.getString(_keySessions);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list.map((e) => SessionResult.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> saveSession(SessionResult session) async {
    final sessions = loadSessions()..insert(0, session);
    await _prefs.setString(_keySessions, jsonEncode(sessions.map((s) => s.toJson()).toList()));
  }

  Future<void> clearSessions() => _prefs.remove(_keySessions);

  // --- In-progress quiz ---

  InProgressQuiz? loadInProgress() {
    final raw = _prefs.getString(_keyInProgress);
    if (raw == null) return null;
    try {
      return InProgressQuiz.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveInProgress(InProgressQuiz quiz) =>
      _prefs.setString(_keyInProgress, jsonEncode(quiz.toJson()));

  Future<void> clearInProgress() => _prefs.remove(_keyInProgress);

  // --- File history ---

  List<SavedFile> loadFileHistory() {
    final raw = _prefs.getString(_keyFileHistory);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list.map((e) => SavedFile.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> addToFileHistory(SavedFile file) async {
    final history = loadFileHistory();
    history.removeWhere((f) => f.name == file.name);
    history.insert(0, file);
    final trimmed = history.take(_maxFileHistory).toList();
    await _prefs.setString(_keyFileHistory, jsonEncode(trimmed.map((f) => f.toJson()).toList()));
  }

  Future<void> removeFromFileHistory(String name) async {
    final history = loadFileHistory()..removeWhere((f) => f.name == name);
    await _prefs.setString(_keyFileHistory, jsonEncode(history.map((f) => f.toJson()).toList()));
  }
}

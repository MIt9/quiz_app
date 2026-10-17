import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../models/question.dart';
import '../services/storage_service.dart';

class TtsProvider extends ChangeNotifier {
  final FlutterTts _tts = FlutterTts();
  final StorageService _storage;

  bool _isPlaying = false;
  double _rate = 0.45;
  double _pitch = 1.0;
  String _language = 'uk-UA';
  List<String> _availableLanguages = [];
  bool _loadingLanguages = false;

  bool get isPlaying => _isPlaying;
  double get rate => _rate;
  double get pitch => _pitch;
  String get language => _language;
  List<String> get availableLanguages => _availableLanguages;
  bool get loadingLanguages => _loadingLanguages;

  TtsProvider(this._storage) {
    _rate = _storage.ttsRate;
    _pitch = _storage.ttsPitch;
    _language = _storage.ttsLanguage;
    _init();
  }

  Future<void> _init() async {
    await _applySettings();

    _tts.setCompletionHandler(() {
      _isPlaying = false;
      notifyListeners();
    });
    _tts.setCancelHandler(() {
      _isPlaying = false;
      notifyListeners();
    });
    _tts.setErrorHandler((_) {
      _isPlaying = false;
      notifyListeners();
    });
  }

  Future<void> _applySettings() async {
    await _tts.setLanguage(_language);
    await _tts.setSpeechRate(_rate);
    await _tts.setPitch(_pitch);
    await _tts.setVolume(1.0);
  }

  Future<void> fetchLanguages() async {
    _loadingLanguages = true;
    notifyListeners();
    try {
      final langs = await _tts.getLanguages as List<dynamic>?;
      if (langs != null) {
        _availableLanguages = langs
            .map((l) => l.toString())
            .toList()
          ..sort();
      }
    } finally {
      _loadingLanguages = false;
      notifyListeners();
    }
  }

  Future<void> setRate(double value) async {
    _rate = value;
    await _tts.setSpeechRate(value);
    await _storage.saveTtsRate(value);
    notifyListeners();
  }

  Future<void> setPitch(double value) async {
    _pitch = value;
    await _tts.setPitch(value);
    await _storage.saveTtsPitch(value);
    notifyListeners();
  }

  Future<void> setLanguage(String lang) async {
    _language = lang;
    await _tts.setLanguage(lang);
    await _storage.saveTtsLanguage(lang);
    notifyListeners();
  }

  Future<void> speakQuestion(Question q) async {
    final labels = ['А', 'Б', 'В', 'Г'];
    final buffer = StringBuffer();
    buffer.write('${q.question} ');
    for (var i = 0; i < q.options.length; i++) {
      buffer.write('Варіант ${labels[i]}: ${q.options[i]}. ');
    }
    await _speak(buffer.toString());
  }

  Future<void> speakText(String text) => _speak(text);

  Future<void> _speak(String text) async {
    await _tts.stop();
    _isPlaying = true;
    notifyListeners();
    await _tts.speak(text);
  }

  Future<void> stop() async {
    await _tts.stop();
    _isPlaying = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }
}

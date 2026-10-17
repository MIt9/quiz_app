import 'package:flutter/foundation.dart';
import '../services/gemini_service.dart';
import '../services/storage_service.dart';

class SettingsProvider extends ChangeNotifier {
  final StorageService storage;

  String _apiKey = '';
  String _selectedModel = '';
  List<String> _models = [];
  bool _loadingModels = false;
  String? _modelsError;

  SettingsProvider(this.storage) {
    _apiKey = storage.apiKey;
    _selectedModel = storage.selectedModel;
  }

  String get apiKey => _apiKey;
  String get selectedModel => _selectedModel;
  List<String> get models => _models;
  bool get loadingModels => _loadingModels;
  String? get modelsError => _modelsError;

  Future<void> saveApiKey(String key) async {
    _apiKey = key;
    await storage.saveApiKey(key);
    notifyListeners();
  }

  String get libraryUrl => storage.libraryUrl;

  Future<void> saveLibraryUrl(String url) => storage.saveLibraryUrl(url);

  Future<void> selectModel(String model) async {
    _selectedModel = model;
    await storage.saveSelectedModel(model);
    notifyListeners();
  }

  Future<void> fetchModels() async {
    if (_apiKey.isEmpty) {
      _modelsError = 'Введіть API ключ';
      notifyListeners();
      return;
    }

    _loadingModels = true;
    _modelsError = null;
    notifyListeners();

    try {
      final service = GeminiService(apiKey: _apiKey, model: '');
      _models = await service.fetchModels();
      if (_selectedModel.isNotEmpty && !_models.contains(_selectedModel)) {
        _selectedModel = '';
        await storage.saveSelectedModel('');
      }
    } catch (e) {
      _modelsError = e.toString();
    } finally {
      _loadingModels = false;
      notifyListeners();
    }
  }
}

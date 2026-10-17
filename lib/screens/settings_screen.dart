import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../providers/tts_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _apiKeyController;
  late final TextEditingController _libraryUrlController;
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    final settings = context.read<SettingsProvider>();
    _apiKeyController = TextEditingController(text: settings.apiKey);
    _libraryUrlController = TextEditingController(text: settings.libraryUrl);
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _libraryUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Налаштування')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ── Gemini API ──
          Text('Gemini API', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          Consumer<SettingsProvider>(
            builder: (context, settings, _) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _apiKeyController,
                  obscureText: _obscure,
                  decoration: InputDecoration(
                    labelText: 'API ключ',
                    hintText: 'AIza...',
                    border: const OutlineInputBorder(),
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                        IconButton(
                          icon: const Icon(Icons.save),
                          tooltip: 'Зберегти',
                          onPressed: () async {
                            await settings.saveApiKey(_apiKeyController.text.trim());
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('API ключ збережено')),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: settings.loadingModels ? null : settings.fetchModels,
                    icon: settings.loadingModels
                        ? const SizedBox(
                            width: 16, height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.refresh),
                    label: const Text('Отримати список моделей'),
                  ),
                ),
                if (settings.modelsError != null) ...[
                  const SizedBox(height: 8),
                  _ErrorBox(settings.modelsError!),
                ],
                if (settings.models.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Text('Модель', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  ...settings.models.map((model) => RadioListTile<String>(
                        value: model,
                        groupValue: settings.selectedModel,
                        title: Text(model, style: const TextStyle(fontSize: 14)),
                        onChanged: (v) => settings.selectModel(v!),
                        contentPadding: EdgeInsets.zero,
                      )),
                ],
                if (settings.selectedModel.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _ActiveChip('Активна модель: ${settings.selectedModel}'),
                ],
              ],
            ),
          ),

          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 16),

          // ── Library ──
          Text('Бібліотека квізів', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          TextField(
            controller: _libraryUrlController,
            decoration: InputDecoration(
              labelText: 'URL репозиторію (https)',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: const Icon(Icons.save),
                tooltip: 'Зберегти',
                onPressed: () async {
                  await context
                      .read<SettingsProvider>()
                      .saveLibraryUrl(_libraryUrlController.text.trim());
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('URL бібліотеки збережено')),
                    );
                  }
                },
              ),
            ),
          ),

          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 16),

          // ── TTS ──
          Text('Голосове читання (TTS)', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          Consumer<TtsProvider>(
            builder: (context, tts, _) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Rate
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Швидкість'),
                    Text(
                      _rateLabel(tts.rate),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: tts.rate,
                  min: 0.1,
                  max: 1.0,
                  divisions: 9,
                  onChanged: tts.setRate,
                ),
                const SizedBox(height: 8),

                // Pitch
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Тон голосу'),
                    Text(
                      _pitchLabel(tts.pitch),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: tts.pitch,
                  min: 0.5,
                  max: 2.0,
                  divisions: 6,
                  onChanged: tts.setPitch,
                ),
                const SizedBox(height: 16),

                // Language
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: tts.loadingLanguages ? null : tts.fetchLanguages,
                        icon: tts.loadingLanguages
                            ? const SizedBox(
                                width: 16, height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.language),
                        label: const Text('Мови на пристрої'),
                      ),
                    ),
                  ],
                ),
                if (tts.availableLanguages.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text('Мова', style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 4),
                  _LanguageDropdown(
                    languages: tts.availableLanguages,
                    selected: tts.language,
                    onChanged: tts.setLanguage,
                  ),
                ],
                if (tts.availableLanguages.isEmpty) ...[
                  const SizedBox(height: 8),
                  _ActiveChip('Поточна мова: ${tts.language}'),
                ],
                const SizedBox(height: 20),

                // Test button
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.tonal(
                    onPressed: () => tts.isPlaying
                        ? tts.stop()
                        : tts.speakText(
                            'Питання: Що таке Flutter? '
                            'Варіант А: Фреймворк для розробки мобільних застосунків. '
                            'Варіант Б: База даних. '
                            'Варіант В: Мова програмування. '
                            'Варіант Г: Хмарний сервіс.',
                          ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(tts.isPlaying ? Icons.stop : Icons.play_arrow),
                        const SizedBox(width: 8),
                        Text(tts.isPlaying ? 'Зупинити' : 'Тест голосу'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  String _rateLabel(double v) {
    if (v <= 0.2) return 'Дуже повільно';
    if (v <= 0.4) return 'Повільно';
    if (v <= 0.6) return 'Нормально';
    if (v <= 0.8) return 'Швидко';
    return 'Дуже швидко';
  }

  String _pitchLabel(double v) {
    if (v <= 0.7) return 'Низький';
    if (v <= 1.2) return 'Нормальний';
    if (v <= 1.6) return 'Високий';
    return 'Дуже високий';
  }
}

class _LanguageDropdown extends StatelessWidget {
  final List<String> languages;
  final String selected;
  final ValueChanged<String> onChanged;

  const _LanguageDropdown({
    required this.languages,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveSelected = languages.contains(selected) ? selected : languages.first;
    return DropdownButtonFormField<String>(
      value: effectiveSelected,
      decoration: const InputDecoration(border: OutlineInputBorder()),
      isExpanded: true,
      items: languages
          .map((l) => DropdownMenuItem(value: l, child: Text(l, style: const TextStyle(fontSize: 14))))
          .toList(),
      onChanged: (v) => v != null ? onChanged(v) : null,
    );
  }
}

class _ErrorBox extends StatelessWidget {
  final String message;
  const _ErrorBox(this.message);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          message,
          style: TextStyle(
              color: Theme.of(context).colorScheme.onErrorContainer, fontSize: 13),
        ),
      );
}

class _ActiveChip extends StatelessWidget {
  final String text;
  const _ActiveChip(this.text);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.check_circle,
                color: Theme.of(context).colorScheme.onPrimaryContainer, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      );
}

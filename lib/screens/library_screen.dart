import 'package:flutter/material.dart';
import '../models/question.dart';
import '../services/remote_quiz_service.dart';
import '../services/storage_service.dart';

/// Pops with `(List<Question>, String name)` when a quiz is downloaded.
class LibraryScreen extends StatefulWidget {
  final StorageService storage;

  const LibraryScreen({super.key, required this.storage});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  late final RemoteQuizService _service = RemoteQuizService(widget.storage.libraryUrl);
  List<RemoteLanguage>? _languages;
  String? _error;
  bool _offline = false;
  bool _loading = true;
  String? _downloading;

  @override
  void initState() {
    super.initState();
    _loadIndex();
  }

  Future<void> _loadIndex() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final raw = await _service.fetchIndexRaw();
      final languages = RemoteQuizService.parseIndex(raw);
      await widget.storage.saveLibraryIndexCache(raw);
      _languages = languages;
      _offline = false;
    } catch (e) {
      final cached = widget.storage.libraryIndexCache;
      if (cached != null) {
        _languages = RemoteQuizService.parseIndex(cached);
        _offline = true;
      } else {
        _error = _message(e);
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  String _message(Object e) => e is FormatException ? e.message : e.toString();

  Future<void> _download(RemoteQuizInfo quiz) async {
    setState(() => _downloading = quiz.file);
    try {
      final List<Question> questions = await _service.fetchQuiz(quiz.file);
      if (mounted) Navigator.pop(context, (questions, quiz.file));
    } catch (e) {
      if (!mounted) return;
      setState(() => _downloading = null);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Помилка завантаження: ${_message(e)}'),
        backgroundColor: Theme.of(context).colorScheme.error,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Бібліотека квізів'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Оновити',
            onPressed: _loading ? null : _loadIndex,
          ),
        ],
      ),
      body: _body(),
    );
  }

  Widget _body() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton(onPressed: _loadIndex, child: const Text('Спробувати знову')),
            ],
          ),
        ),
      );
    }
    final languages = _languages ?? [];
    if (languages.isEmpty) return const Center(child: Text('Бібліотека порожня'));

    return ListView(
      children: [
        if (_offline)
          const ListTile(
            leading: Icon(Icons.cloud_off),
            title: Text('Немає мережі, показано збережений список'),
          ),
        for (final lang in languages)
          ExpansionTile(
            title: Text(lang.title),
            subtitle: Text('${lang.quizzes.length} квізів'),
            initiallyExpanded: languages.length == 1,
            children: [
              for (final quiz in lang.quizzes)
                ListTile(
                  title: Text(quiz.title),
                  subtitle: quiz.questions == null ? null : Text('${quiz.questions} питань'),
                  trailing: _downloading == quiz.file
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.download),
                  onTap: _downloading == null ? () => _download(quiz) : null,
                ),
            ],
          ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/question.dart';
import '../models/saved_file.dart';
import '../providers/quiz_provider.dart';
import '../services/file_import_service.dart';
import '../services/storage_service.dart';
import 'history_screen.dart';
import 'library_screen.dart';
import 'quiz_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  final StorageService storage;

  const HomeScreen({super.key, required this.storage});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Question>? _loadedQuestions;
  String? _loadedFileName;
  bool _importing = false;
  List<SavedFile> _fileHistory = [];
  bool _hasInProgress = false;
  int _inProgressCurrent = 0;
  int _inProgressTotal = 0;

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  void _loadState() {
    _fileHistory = widget.storage.loadFileHistory();
    final inProgress = widget.storage.loadInProgress();
    if (inProgress != null) {
      _hasInProgress = true;
      _inProgressCurrent = inProgress.currentIndex + 1;
      _inProgressTotal = inProgress.questions.length;
    }
  }

  Future<void> _importFile() async {
    setState(() => _importing = true);
    try {
      final service = FileImportService();
      final result = await service.pickAndParseWithName();
      if (result == null) return;

      await _applyLoaded(result.$1, result.$2);
    } catch (e) {
      _showError('Помилка читання файлу: ${e is FormatException ? e.message : e}');
    } finally {
      setState(() => _importing = false);
    }
  }

  Future<void> _openLibrary() async {
    final result = await Navigator.push<(List<Question>, String)>(
      context,
      MaterialPageRoute(builder: (_) => LibraryScreen(storage: widget.storage)),
    );
    if (result == null) return;
    await _applyLoaded(result.$1, result.$2);
  }

  Future<void> _applyLoaded(List<Question> questions, String name) async {
    if (questions.isEmpty) {
      _showError('Файл не містить питань');
      return;
    }

    await widget.storage.addToFileHistory(SavedFile(
      name: name,
      savedAt: DateTime.now(),
      questions: questions,
    ));

    setState(() {
      _loadedQuestions = questions;
      _loadedFileName = name;
      _fileHistory = widget.storage.loadFileHistory();
    });
  }

  void _selectFromHistory(SavedFile file) {
    setState(() {
      _loadedQuestions = file.questions;
      _loadedFileName = file.name;
    });
  }

  void _removeFromHistory(SavedFile file) async {
    await widget.storage.removeFromFileHistory(file.name);
    setState(() {
      _fileHistory = widget.storage.loadFileHistory();
      if (_loadedFileName == file.name) {
        _loadedQuestions = null;
        _loadedFileName = null;
      }
    });
  }

  void _startQuiz() {
    if (_loadedQuestions == null) return;
    context.read<QuizProvider>().startQuiz(_loadedQuestions!);
    Navigator.push(context, MaterialPageRoute(builder: (_) => const QuizScreen()));
  }

  void _continueQuiz() {
    final inProgress = widget.storage.loadInProgress();
    if (inProgress == null) return;
    context.read<QuizProvider>().resumeQuiz(inProgress);
    Navigator.push(context, MaterialPageRoute(builder: (_) => const QuizScreen())).then((_) {
      setState(_loadState);
    });
  }

  void _cancelInProgress() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Скасувати прогрес?'),
        content: const Text('Поточний прогрес буде видалено.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Ні')),
          TextButton(
            onPressed: () {
              widget.storage.clearInProgress();
              setState(() => _hasInProgress = false);
              Navigator.pop(context);
            },
            child: const Text('Так'),
          ),
        ],
      ),
    );
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: Theme.of(context).colorScheme.error,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quiz App'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Історія',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => HistoryScreen(storage: widget.storage)),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Налаштування',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 12),
          const Icon(Icons.quiz_outlined, size: 64, color: Colors.deepPurple),
          const SizedBox(height: 16),
          const Text(
            'Підготовка до інтерв\'ю',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // --- Continue banner ---
          if (_hasInProgress) ...[
            _ContinueBanner(
              current: _inProgressCurrent,
              total: _inProgressTotal,
              onContinue: () {
                _continueQuiz();
              },
              onCancel: _cancelInProgress,
            ),
            const SizedBox(height: 20),
          ],

          // --- Import ---
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _importing ? null : _importFile,
              icon: _importing
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.upload_file),
              label: Text(_importing ? 'Завантаження...' : 'Обрати новий файл'),
            ),
          ),

          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _openLibrary,
              icon: const Icon(Icons.cloud_download_outlined),
              label: const Text('Бібліотека квізів'),
            ),
          ),

          // --- File history ---
          if (_fileHistory.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text('Збережені файли', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            ..._fileHistory.map((file) => _FileHistoryTile(
                  file: file,
                  isSelected: _loadedFileName == file.name,
                  onTap: () => _selectFromHistory(file),
                  onDelete: () => _removeFromHistory(file),
                )),
          ],

          // --- Selected file indicator ---
          if (_loadedFileName != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.green.withAlpha(25),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.withAlpha(80)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '$_loadedFileName • ${_loadedQuestions?.length} питань',
                      style: const TextStyle(color: Colors.green),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _loadedQuestions != null ? _startQuiz : null,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Почати квіз'),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _ContinueBanner extends StatelessWidget {
  final int current;
  final int total;
  final VoidCallback onContinue;
  final VoidCallback onCancel;

  const _ContinueBanner({
    required this.current,
    required this.total,
    required this.onContinue,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final percent = total == 0 ? 0.0 : (current - 1) / total;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.pause_circle, color: Theme.of(context).colorScheme.onPrimaryContainer),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Незавершений квіз',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.close, size: 18, color: Theme.of(context).colorScheme.onPrimaryContainer),
                onPressed: onCancel,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: percent,
            backgroundColor: Theme.of(context).colorScheme.onPrimaryContainer.withAlpha(40),
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
          const SizedBox(height: 6),
          Text(
            'Питання $current з $total',
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.tonal(
              onPressed: onContinue,
              child: const Text('Продовжити'),
            ),
          ),
        ],
      ),
    );
  }
}

class _FileHistoryTile extends StatelessWidget {
  final SavedFile file;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _FileHistoryTile({
    required this.file,
    required this.isSelected,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      color: isSelected ? Theme.of(context).colorScheme.secondaryContainer : null,
      child: ListTile(
        leading: Icon(
          Icons.description_outlined,
          color: isSelected ? Theme.of(context).colorScheme.onSecondaryContainer : null,
        ),
        title: Text(
          file.name,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Theme.of(context).colorScheme.onSecondaryContainer : null,
          ),
        ),
        subtitle: Text(
          '${file.questionCount} питань',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, size: 18),
          onPressed: onDelete,
        ),
        onTap: onTap,
      ),
    );
  }
}

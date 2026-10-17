import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/session_result.dart';
import '../services/storage_service.dart';

class HistoryScreen extends StatefulWidget {
  final StorageService storage;

  const HistoryScreen({super.key, required this.storage});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late List<SessionResult> _sessions;
  final _dateFormat = DateFormat('dd.MM.yyyy HH:mm');

  @override
  void initState() {
    super.initState();
    _sessions = widget.storage.loadSessions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Історія результатів'),
        actions: [
          if (_sessions.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Очистити',
              onPressed: _confirmClear,
            ),
        ],
      ),
      body: _sessions.isEmpty
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.history, size: 64, color: Colors.grey),
                  SizedBox(height: 12),
                  Text('Немає результатів', style: TextStyle(color: Colors.grey)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _sessions.length,
              itemBuilder: (context, i) {
                final s = _sessions[i];
                return _SessionCard(session: s, dateFormat: _dateFormat);
              },
            ),
    );
  }

  void _confirmClear() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Очистити історію?'),
        content: const Text('Всі результати буде видалено.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Скасувати')),
          TextButton(
            onPressed: () async {
              await widget.storage.clearSessions();
              setState(() => _sessions = []);
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Очистити'),
          ),
        ],
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  final SessionResult session;
  final DateFormat dateFormat;

  const _SessionCard({required this.session, required this.dateFormat});

  @override
  Widget build(BuildContext context) {
    final percent = session.scorePercent;
    final color = percent >= 80
        ? Colors.green
        : percent >= 50
            ? Colors.orange
            : Theme.of(context).colorScheme.error;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ExpansionTile(
        leading: _MiniCircle(percent: percent / 100, color: color),
        title: Text(
          '${session.correctAnswers} / ${session.totalQuestions} правильно',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(dateFormat.format(session.date), style: const TextStyle(fontSize: 12)),
        trailing: Text(
          '${percent.round()}%',
          style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 16),
        ),
        children: session.questionResults
            .map((r) => ListTile(
                  dense: true,
                  leading: Icon(
                    r.isCorrect ? Icons.check_circle : Icons.cancel,
                    color: r.isCorrect ? Colors.green : Theme.of(context).colorScheme.error,
                    size: 20,
                  ),
                  title: Text(r.questionText,
                      style: const TextStyle(fontSize: 13),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                ))
            .toList(),
      ),
    );
  }
}

class _MiniCircle extends StatelessWidget {
  final double percent;
  final Color color;

  const _MiniCircle({required this.percent, required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 44,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: percent,
            strokeWidth: 4,
            color: color,
            backgroundColor: color.withAlpha(40),
          ),
        ],
      ),
    );
  }
}

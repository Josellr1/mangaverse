// lib/screens/history_screen.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/history_service.dart';
import '../theme/app_theme.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<HistoryEntry> _history = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _load();
  }

  Future<void> _load() async {
    final h = await HistoryService.getHistory();
    if (mounted) setState(() { _history = h; _loading = false; });
  }

  Future<void> _clearAll() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        title: const Text('Limpiar historial', style: TextStyle(color: AppColors.textMain)),
        content: const Text('¿Borrar todo el historial de lectura?',
            style: TextStyle(color: AppColors.textMuted)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar', style: TextStyle(color: AppColors.textMuted))),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Borrar', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await HistoryService.clearHistory();
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: RichText(
          text: const TextSpan(
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.textMain),
            children: [
              TextSpan(text: 'Historial '),
              TextSpan(text: 'de Lectura', style: TextStyle(color: AppColors.primary)),
            ],
          ),
        ),
        automaticallyImplyLeading: false,
        actions: [
          if (_history.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined, color: AppColors.textMuted),
              tooltip: 'Limpiar historial',
              onPressed: _clearAll,
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _history.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.history_outlined,
                          size: 64, color: AppColors.primary.withOpacity(0.35)),
                      const SizedBox(height: 16),
                      const Text('No has leído nada todavía.',
                          style: TextStyle(color: AppColors.textMuted, fontSize: 16)),
                      const SizedBox(height: 8),
                      const Text('Los capítulos que leas aparecerán aquí.',
                          style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                          textAlign: TextAlign.center),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: _history.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) => _HistoryTile(entry: _history[i]),
                ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final HistoryEntry entry;
  const _HistoryTile({required this.entry});

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Hace ${diff.inHours}h';
    if (diff.inDays < 7) return 'Hace ${diff.inDays}d';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          // Cover thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: entry.coverUrl != null
                ? CachedNetworkImage(
                    imageUrl: entry.coverUrl!,
                    width: 48,
                    height: 68,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => _placeholder(),
                  )
                : _placeholder(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.mangaTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  entry.chapterTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.secondary, fontSize: 13),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 12, color: AppColors.textMuted),
                    const SizedBox(width: 4),
                    Text(_timeAgo(entry.readAt),
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                  ],
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.textMuted, size: 20),
        ],
      ),
    );
  }

  Widget _placeholder() => Container(
        width: 48,
        height: 68,
        decoration: BoxDecoration(
          color: AppColors.bgSurface,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.book_outlined, color: AppColors.textMuted, size: 20),
      );
}

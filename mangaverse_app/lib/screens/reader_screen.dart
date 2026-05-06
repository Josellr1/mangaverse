// lib/screens/reader_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/manga_model.dart';
import '../services/api_service.dart';
import '../services/history_service.dart';
import '../theme/app_theme.dart';

class ReaderScreen extends StatefulWidget {
  final String chapterId;
  final String chapterTitle;
  final List<Chapter> chapters;
  final int currentIndex;
  final String mangaId;
  final String mangaTitle;
  final String? coverUrl;

  const ReaderScreen({
    super.key,
    required this.chapterId,
    required this.chapterTitle,
    required this.chapters,
    required this.currentIndex,
    required this.mangaId,
    required this.mangaTitle,
    this.coverUrl,
  });

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  List<String> _pages = [];
  bool _loading = true;
  bool _barsVisible = true;
  late int _chapterIndex;
  late String _currentChapterId;
  late String _currentChapterTitle;

  @override
  void initState() {
    super.initState();
    _chapterIndex = widget.currentIndex;
    _currentChapterId = widget.chapterId;
    _currentChapterTitle = widget.chapterTitle;
    // Full-screen immersive
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _loadPages(_currentChapterId);
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  Future<void> _loadPages(String chapterId) async {
    setState(() { _loading = true; _pages = []; });
    final pages = await ApiService.getChapterPages(chapterId);
    if (mounted) {
      setState(() { _pages = pages; _loading = false; });
      // Record to history
      await HistoryService.addEntry(HistoryEntry(
        chapterId: chapterId,
        mangaId: widget.mangaId,
        mangaTitle: widget.mangaTitle,
        coverUrl: widget.coverUrl,
        chapterTitle: _currentChapterTitle,
        readAt: DateTime.now(),
      ));
    }
  }

  void _goToChapter(int newIndex) {
    if (newIndex < 0 || newIndex >= widget.chapters.length) return;
    final ch = widget.chapters[newIndex];
    setState(() {
      _chapterIndex = newIndex;
      _currentChapterId = ch.id;
      _currentChapterTitle = ch.displayTitle;
    });
    _loadPages(ch.id);
  }

  void _toggleBars() => setState(() => _barsVisible = !_barsVisible);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Pages
          _loading
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.primary))
              : _pages.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline,
                              color: AppColors.textMuted, size: 48),
                          const SizedBox(height: 12),
                          const Text('No se pudieron cargar las páginas.',
                              style: TextStyle(color: AppColors.textMuted)),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => _loadPages(_currentChapterId),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary),
                            child: const Text('Reintentar'),
                          ),
                        ],
                      ),
                    )
                  : GestureDetector(
                      onTap: _toggleBars,
                      child: ListView.builder(
                        itemCount: _pages.length,
                        itemBuilder: (_, i) => CachedNetworkImage(
                          imageUrl: _pages[i],
                          fit: BoxFit.fitWidth,
                          width: double.infinity,
                          placeholder: (_, __) => const SizedBox(
                            height: 200,
                            child: Center(
                              child: CircularProgressIndicator(
                                  color: AppColors.primary, strokeWidth: 2),
                            ),
                          ),
                          errorWidget: (_, __, ___) => const SizedBox(
                            height: 80,
                            child: Center(
                              child: Icon(Icons.broken_image,
                                  color: AppColors.textMuted),
                            ),
                          ),
                        ),
                      ),
                    ),

          // TOP BAR
          AnimatedPositioned(
            duration: const Duration(milliseconds: 250),
            top: _barsVisible ? 0 : -80,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 4, left: 4, right: 16, bottom: 8),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.black87, Colors.transparent],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Text(
                      _currentChapterTitle,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 15),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // BOTTOM BAR — Prev/Next chapter
          AnimatedPositioned(
            duration: const Duration(milliseconds: 250),
            bottom: _barsVisible ? 0 : -80,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).padding.bottom + 8,
                  left: 16, right: 16, top: 12),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.transparent, Colors.black87],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _navBtn(
                      icon: Icons.chevron_left,
                      label: 'Anterior',
                      enabled: _chapterIndex < widget.chapters.length - 1,
                      onTap: () => _goToChapter(_chapterIndex + 1),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _navBtn(
                      icon: Icons.chevron_right,
                      label: 'Siguiente',
                      enabled: _chapterIndex > 0,
                      onTap: () => _goToChapter(_chapterIndex - 1),
                      iconAfter: true,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _navBtn({
    required IconData icon,
    required String label,
    required bool enabled,
    required VoidCallback onTap,
    bool iconAfter = false,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedOpacity(
        opacity: enabled ? 1.0 : 0.35,
        duration: const Duration(milliseconds: 200),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.85),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: iconAfter
                ? [
                    Text(label,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 14)),
                    Icon(icon, color: Colors.white, size: 20),
                  ]
                : [
                    Icon(icon, color: Colors.white, size: 20),
                    Text(label,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 14)),
                  ],
          ),
        ),
      ),
    );
  }
}

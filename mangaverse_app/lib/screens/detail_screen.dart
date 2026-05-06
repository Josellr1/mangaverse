// lib/screens/detail_screen.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/manga_model.dart';
import '../services/api_service.dart';
import '../services/favorites_service.dart';
import '../theme/app_theme.dart';
import 'reader_screen.dart';

class DetailScreen extends StatefulWidget {
  final String mangaId;
  const DetailScreen({super.key, required this.mangaId});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  Manga? _manga;
  List<Chapter> _chapters = [];
  bool _loading = true;
  bool _isFav = false;
  String _lang = 'es';
  bool _rawJson = false;
  // Store raw json for favorites
  Map<String, dynamic>? _rawMangaJson;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final manga = await ApiService.getManga(widget.mangaId);
    final isFav = await FavoritesService.isFavorite(widget.mangaId);
    final chapters = await ApiService.getChapters(widget.mangaId, lang: _lang);
    if (mounted) {
      setState(() {
        _manga = manga;
        _chapters = chapters;
        _isFav = isFav;
        _loading = false;
      });
    }
  }

  Future<void> _reloadChapters() async {
    final chapters = await ApiService.getChapters(widget.mangaId, lang: _lang);
    if (mounted) setState(() => _chapters = chapters);
  }

  Future<void> _toggleFav() async {
    if (_manga == null) return;
    // Build minimal json for storage
    final json = {
      'id': _manga!.id,
      'attributes': {
        'title': {'en': _manga!.title},
        'description': {'en': _manga!.description ?? ''},
        'status': _manga!.status,
        'year': _manga!.year,
        'tags': [],
      },
      'relationships': _manga!.coverUrl != null
          ? [
              {
                'type': 'cover_art',
                'attributes': {
                  'fileName': _manga!.coverUrl!
                      .split('/')
                      .last
                      .replaceAll('.256.jpg', ''),
                },
              }
            ]
          : [],
    };
    await FavoritesService.toggle(json);
    if (mounted) setState(() => _isFav = !_isFav);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : _manga == null
              ? const Center(
                  child: Text('Error al cargar',
                      style: TextStyle(color: AppColors.textMuted)))
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    final manga = _manga!;
    return CustomScrollView(
      slivers: [
        // Hero App Bar
        SliverAppBar(
          expandedHeight: 320,
          pinned: true,
          backgroundColor: AppColors.bg,
          leading: BackButton(color: AppColors.textMain),
          actions: [
            IconButton(
              icon: Icon(_isFav ? Icons.favorite : Icons.favorite_outline,
                  color: _isFav ? AppColors.primary : AppColors.textMuted),
              onPressed: _toggleFav,
              tooltip: _isFav ? 'Quitar de favoritos' : 'Añadir a favoritos',
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: Stack(
              fit: StackFit.expand,
              children: [
                // Blurred background
                manga.coverUrl != null
                    ? CachedNetworkImage(
                        imageUrl: manga.coverUrl!,
                        fit: BoxFit.cover,
                        color: Colors.black54,
                        colorBlendMode: BlendMode.darken,
                        errorWidget: (_, __, ___) => Container(color: AppColors.bgCard),
                      )
                    : Container(color: AppColors.bgCard),
                // Cover centered
                Center(
                  child: Hero(
                    tag: 'cover_${manga.id}',
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: manga.coverUrl != null
                          ? CachedNetworkImage(
                              imageUrl: manga.coverUrl!,
                              height: 220,
                              fit: BoxFit.contain,
                              errorWidget: (_, __, ___) =>
                                  const Icon(Icons.book, size: 80, color: AppColors.textMuted),
                            )
                          : const Icon(Icons.book, size: 80, color: AppColors.textMuted),
                    ),
                  ),
                ),
                // Gradient bottom
                const Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.transparent, AppColors.bg],
                        begin: Alignment.center,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Content
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // Title
              Text(manga.title,
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w900)),
              const SizedBox(height: 4),
              if (manga.author != null)
                Text('✍️ ${manga.author}',
                    style: const TextStyle(
                        color: AppColors.secondary, fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              // Metadata chips
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  if (manga.status != null) _chip(_statusLabel(manga.status!), AppColors.primary),
                  if (manga.year != null) _chip('📅 ${manga.year}', AppColors.textMuted),
                  ...manga.tags.map((t) => _chip(t, AppColors.secondary)),
                ],
              ),
              const SizedBox(height: 16),
              // Description
              if (manga.description != null && manga.description!.isNotEmpty)
                Text(
                  manga.description!.length > 400
                      ? '${manga.description!.substring(0, 400)}...'
                      : manga.description!,
                  style: const TextStyle(
                      color: AppColors.textMuted, fontSize: 14, height: 1.6),
                ),
              const SizedBox(height: 24),
              // Chapters header
              Row(
                children: [
                  const Text('📖 Capítulos',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  const Spacer(),
                  Text('${_chapters.length}',
                      style: const TextStyle(
                          color: AppColors.textMuted, fontSize: 14)),
                ],
              ),
              const SizedBox(height: 8),
              // Language filter
              Row(
                children: [
                  _langBtn('es', '🇪🇸 Español'),
                  const SizedBox(width: 8),
                  _langBtn('en', '🇺🇸 English'),
                  const SizedBox(width: 8),
                  _langBtn('all', '🌐 Todos'),
                ],
              ),
              const SizedBox(height: 12),
              // Chapters list
              if (_chapters.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.bgCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Text(
                    'No hay capítulos en este idioma.\nPrueba con "Todos".',
                    style: TextStyle(color: AppColors.textMuted),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _chapters.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 6),
                  itemBuilder: (_, i) => _chapterTile(_chapters[i], i),
                ),
              const SizedBox(height: 40),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _chapterTile(Chapter ch, int index) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ReaderScreen(
            chapterId: ch.id,
            chapterTitle: ch.displayTitle,
            chapters: _chapters,
            currentIndex: index,
          ),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(ch.displayTitle,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text('${ch.langFlag} ${ch.language}',
                            style: const TextStyle(
                                color: AppColors.secondary,
                                fontSize: 11,
                                fontWeight: FontWeight.w600)),
                      ),
                      if (ch.scanlationGroup != null) ...[
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(ch.scanlationGroup!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: AppColors.textMuted, fontSize: 11)),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            if (ch.publishedAt != null)
              Text(
                '${ch.publishedAt!.day}/${ch.publishedAt!.month}/${ch.publishedAt!.year}',
                style: const TextStyle(
                    color: AppColors.textMuted, fontSize: 11),
              ),
            const SizedBox(width: 8),
            const Icon(Icons.play_circle_outline,
                color: AppColors.primary, size: 22),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Text(label,
            style: TextStyle(
                color: color, fontSize: 12, fontWeight: FontWeight.w600)),
      );

  Widget _langBtn(String lang, String label) {
    final active = _lang == lang;
    return GestureDetector(
      onTap: () {
        setState(() => _lang = lang);
        _reloadChapters();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? AppColors.primary.withOpacity(0.2) : AppColors.bgCard,
          border: Border.all(color: active ? AppColors.primary : AppColors.border),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: active ? AppColors.primary : AppColors.textMuted)),
      ),
    );
  }

  String _statusLabel(String s) {
    const map = {
      'ongoing': '🟢 En Curso',
      'completed': '✅ Completado',
      'hiatus': '⏸️ Hiatus',
      'cancelled': '❌ Cancelado',
    };
    return map[s] ?? s;
  }
}

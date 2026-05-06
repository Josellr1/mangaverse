// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../models/manga_model.dart';
import '../services/api_service.dart';
import '../widgets/manga_card.dart';
import '../theme/app_theme.dart';
import 'detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchCtrl = TextEditingController();
  List<Manga> _mangas = [];
  bool _loading = true;
  String _query = '';
  String _activeLang = 'es';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final results = await ApiService.searchMangas(_query, limit: 24);
    if (mounted) setState(() { _mangas = results; _loading = false; });
  }

  void _search() {
    setState(() => _query = _searchCtrl.text.trim());
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            expandedHeight: 160,
            floating: true,
            pinned: true,
            backgroundColor: AppColors.bg,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0x228B5CF6), Colors.transparent],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(16, 80, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: const TextSpan(
                        style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: AppColors.textMain),
                        children: [
                          TextSpan(text: 'Manga'),
                          TextSpan(text: 'Verse', style: TextStyle(color: AppColors.primary)),
                        ],
                      ),
                    ),
                    const Text('Lee sin límites 🌌',
                        style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                  ],
                ),
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(60),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchCtrl,
                        style: const TextStyle(color: AppColors.textMain),
                        decoration: const InputDecoration(
                          hintText: 'Buscar manga, manhwa...',
                          prefixIcon: Icon(Icons.search, color: AppColors.textMuted),
                        ),
                        onSubmitted: (_) => _search(),
                        textInputAction: TextInputAction.search,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _searchBtn(),
                  ],
                ),
              ),
            ),
          ),

          // Language filter
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  Text(
                    _query.isEmpty ? '🔥 Populares' : 'Resultados para "$_query"',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                  const Spacer(),
                  _langChip('es', '🇪🇸 ES'),
                  const SizedBox(width: 6),
                  _langChip('en', '🇺🇸 EN'),
                  const SizedBox(width: 6),
                  _langChip('all', '🌐'),
                ],
              ),
            ),
          ),

          // Grid
          _loading
              ? SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverGrid(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => _shimmerCard(),
                      childCount: 12,
                    ),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.55,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                  ),
                )
              : _mangas.isEmpty
                  ? const SliverFillRemaining(
                      child: Center(
                        child: Text('No se encontraron resultados.',
                            style: TextStyle(color: AppColors.textMuted)),
                      ),
                    )
                  : SliverPadding(
                      padding: const EdgeInsets.all(16),
                      sliver: SliverGrid(
                        delegate: SliverChildBuilderDelegate(
                          (_, i) => MangaCard(
                            manga: _mangas[i],
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => DetailScreen(mangaId: _mangas[i].id),
                              ),
                            ),
                          ),
                          childCount: _mangas.length,
                        ),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.55,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                      ),
                    ),
        ],
      ),
    );
  }

  Widget _searchBtn() => GestureDetector(
        onTap: _search,
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            gradient: AppColors.gradient,
            borderRadius: BorderRadius.circular(50),
          ),
          child: const Icon(Icons.arrow_forward, color: Colors.white),
        ),
      );

  Widget _langChip(String lang, String label) {
    final active = _activeLang == lang;
    return GestureDetector(
      onTap: () { setState(() => _activeLang = lang); },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: active ? AppColors.primary.withOpacity(0.2) : AppColors.bgCard,
          border: Border.all(
              color: active ? AppColors.primary : AppColors.border),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: active ? AppColors.primary : AppColors.textMuted,
            )),
      ),
    );
  }

  Widget _shimmerCard() => Shimmer.fromColors(
        baseColor: AppColors.bgCard,
        highlightColor: AppColors.bgSurface,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      );

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }
}

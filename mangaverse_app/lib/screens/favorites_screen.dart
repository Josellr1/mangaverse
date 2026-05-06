// lib/screens/favorites_screen.dart
import 'package:flutter/material.dart';
import '../models/manga_model.dart';
import '../services/favorites_service.dart';
import '../widgets/manga_card.dart';
import '../theme/app_theme.dart';
import 'detail_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  List<Manga> _favorites = [];
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
    final favs = await FavoritesService.getFavorites();
    if (mounted) setState(() { _favorites = favs; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: RichText(
          text: const TextSpan(
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.textMain),
            children: [
              TextSpan(text: 'Mis '),
              TextSpan(text: 'Favoritos', style: TextStyle(color: AppColors.primary)),
            ],
          ),
        ),
        automaticallyImplyLeading: false,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _favorites.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.favorite_outline,
                          size: 64, color: AppColors.primary.withOpacity(0.4)),
                      const SizedBox(height: 16),
                      const Text('No tienes favoritos aún.',
                          style: TextStyle(color: AppColors.textMuted, fontSize: 16)),
                      const SizedBox(height: 8),
                      const Text('Toca ❤️ en el detalle de un manga para guardarlo.',
                          style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                          textAlign: TextAlign.center),
                    ],
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.55,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: _favorites.length,
                  itemBuilder: (_, i) => MangaCard(
                    manga: _favorites[i],
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DetailScreen(mangaId: _favorites[i].id),
                      ),
                    ).then((_) => _load()),
                  ),
                ),
    );
  }
}

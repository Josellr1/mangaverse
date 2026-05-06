// lib/screens/profile_screen.dart
import 'package:flutter/material.dart';
import '../services/favorites_service.dart';
import '../services/history_service.dart';
import '../theme/app_theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _favCount = 0;
  int _historyCount = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final favs = await FavoritesService.getFavorites();
    final hist = await HistoryService.getCount();
    if (mounted) {
      setState(() {
        _favCount = favs.length;
        _historyCount = hist;
        _loading = false;
      });
    }
  }

  Future<void> _clearHistory() async {
    final confirm = await _confirmDialog(
        'Limpiar historial', '¿Deseas borrar todo tu historial de lectura?');
    if (confirm == true) {
      await HistoryService.clearHistory();
      _loadStats();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Historial eliminado.')),
        );
      }
    }
  }

  Future<void> _clearFavorites() async {
    final confirm = await _confirmDialog(
        'Limpiar favoritos', '¿Deseas eliminar todos tus mangas favoritos?');
    if (confirm == true) {
      await FavoritesService.clearAll();
      _loadStats();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Favoritos eliminados.')),
        );
      }
    }
  }

  Future<bool?> _confirmDialog(String title, String content) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        title: Text(title, style: const TextStyle(color: AppColors.textMain)),
        content: Text(content, style: const TextStyle(color: AppColors.textMuted)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar', style: TextStyle(color: AppColors.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirmar', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Header
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            automaticallyImplyLeading: false,
            backgroundColor: AppColors.bg,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0x448B5CF6), Color(0x2206B6D4)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 60),
                    // Avatar
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppColors.gradient,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.4),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text('MV',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.w900)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text('MangaVerse Reader',
                        style: TextStyle(
                            color: AppColors.textMain,
                            fontSize: 18,
                            fontWeight: FontWeight.w800)),
                    const Text('Usuario local · Sin registro necesario',
                        style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                  ],
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: _loading
                ? const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                  )
                : Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Stats
                        _sectionLabel('📊 Estadísticas'),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: _statCard(
                                icon: Icons.favorite,
                                color: AppColors.primary,
                                label: 'Favoritos',
                                value: '$_favCount',
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _statCard(
                                icon: Icons.history,
                                color: AppColors.secondary,
                                label: 'Cap. Leídos',
                                value: '$_historyCount',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Options
                        _sectionLabel('⚙️ Opciones'),
                        const SizedBox(height: 10),
                        _optionTile(
                          icon: Icons.delete_sweep_outlined,
                          label: 'Limpiar historial de lectura',
                          subtitle: '$_historyCount capítulos registrados',
                          color: AppColors.secondary,
                          onTap: _clearHistory,
                        ),
                        const SizedBox(height: 8),
                        _optionTile(
                          icon: Icons.favorite_border,
                          label: 'Limpiar lista de favoritos',
                          subtitle: '$_favCount mangas guardados',
                          color: AppColors.primary,
                          onTap: _clearFavorites,
                        ),
                        const SizedBox(height: 24),

                        // About
                        _sectionLabel('ℹ️ Acerca de'),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.bgCard,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            children: [
                              _aboutRow('Aplicación', 'MangaVerse'),
                              _divider(),
                              _aboutRow('Versión', '1.0.0 (Beta)'),
                              _divider(),
                              _aboutRow('Fuente de datos', 'MangaDex API'),
                              _divider(),
                              _aboutRow('Desarrollador', '@Josellr1'),
                              _divider(),
                              _aboutRow('Almacenamiento', 'Local · Sin cuenta requerida'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 40),

                        // Legal note
                        const Center(
                          child: Text(
                            'MangaVerse actúa como visor. No aloja\nni distribuye ningún contenido de manga.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 11,
                                height: 1.6),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(text,
      style: const TextStyle(
          fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textMuted));

  Widget _statCard({
    required IconData icon,
    required Color color,
    required String label,
    required String value,
  }) =>
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(value,
                style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: color)),
            Text(label,
                style: const TextStyle(
                    color: AppColors.textMuted, fontSize: 12)),
          ],
        ),
      );

  Widget _optionTile({
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14)),
                    Text(subtitle,
                        style: const TextStyle(
                            color: AppColors.textMuted, fontSize: 12)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textMuted, size: 20),
            ],
          ),
        ),
      );

  Widget _aboutRow(String key, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Text(key,
                style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
            const Spacer(),
            Text(value,
                style: const TextStyle(
                    color: AppColors.textMain,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      );

  Widget _divider() =>
      const Divider(height: 1, color: AppColors.border);
}

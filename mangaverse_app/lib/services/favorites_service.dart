// lib/services/favorites_service.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/manga_model.dart';

class FavoritesService {
  static const _key = 'mv_favorites';

  static Future<List<Map<String, dynamic>>> _raw() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    return (jsonDecode(raw) as List<dynamic>)
        .cast<Map<String, dynamic>>();
  }

  static Future<List<Manga>> getFavorites() async {
    final raw = await _raw();
    return raw.map((e) => Manga.fromJson(e)).toList();
  }

  static Future<bool> isFavorite(String id) async {
    final list = await _raw();
    return list.any((e) => e['id'] == id);
  }

  static Future<void> toggle(Map<String, dynamic> mangaJson) async {
    final prefs = await SharedPreferences.getInstance();
    final list = await _raw();
    final id = mangaJson['id'];
    final idx = list.indexWhere((e) => e['id'] == id);
    if (idx >= 0) {
      list.removeAt(idx);
    } else {
      list.add(mangaJson);
    }
    await prefs.setString(_key, jsonEncode(list));
  }
}

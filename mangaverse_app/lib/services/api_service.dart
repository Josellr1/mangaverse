// lib/services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/manga_model.dart';

class ApiService {
  static const _base = 'https://api.mangadex.org';

  static Map<String, String> get _headers => {
        'User-Agent': 'MangaVerse/1.0',
      };

  /// Search or get popular mangas
  static Future<List<Manga>> searchMangas(
    String query, {
    int limit = 24,
    int offset = 0,
  }) async {
    try {
      final uri = Uri.parse('$_base/manga').replace(queryParameters: {
        if (query.isNotEmpty) 'title': query,
        'limit': '$limit',
        'offset': '$offset',
        'includes[]': ['cover_art', 'author'],
        'order[followedCount]': 'desc',
        'contentRating[]': ['safe', 'suggestive'],
      });

      final res = await http.get(uri, headers: _headers);
      if (res.statusCode != 200) return [];
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      final data = json['data'] as List<dynamic>? ?? [];
      return data.map((e) => Manga.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Get manga details by ID
  static Future<Manga?> getManga(String id) async {
    try {
      final uri = Uri.parse('$_base/manga/$id').replace(queryParameters: {
        'includes[]': ['cover_art', 'author', 'artist'],
      });
      final res = await http.get(uri, headers: _headers);
      if (res.statusCode != 200) return null;
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      return Manga.fromJson(json['data'] as Map<String, dynamic>);
    } catch (e) {
      return null;
    }
  }

  /// Get chapters for a manga
  static Future<List<Chapter>> getChapters(
    String mangaId, {
    String? lang, // null = all
    int limit = 120,
    int offset = 0,
  }) async {
    try {
      final params = <String, dynamic>{
        'limit': '$limit',
        'offset': '$offset',
        'order[chapter]': 'desc',
        'includes[]': 'scanlation_group',
      };
      if (lang == 'es') {
        params['translatedLanguage[]'] = ['es', 'es-la'];
      } else if (lang == 'en') {
        params['translatedLanguage[]'] = ['en'];
      }

      final uri = Uri.parse('$_base/manga/$mangaId/feed')
          .replace(queryParameters: params);

      final res = await http.get(uri, headers: _headers);
      if (res.statusCode != 200) return [];
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      final data = json['data'] as List<dynamic>? ?? [];
      return data
          .map((e) => Chapter.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Get chapter page URLs
  static Future<List<String>> getChapterPages(String chapterId) async {
    try {
      final res = await http.get(
        Uri.parse('$_base/at-home/server/$chapterId'),
        headers: _headers,
      );
      if (res.statusCode != 200) return [];
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      final chapter = json['chapter'] as Map<String, dynamic>;
      final hash = chapter['hash'] as String;
      // Prefer data-saver quality
      final pages = (chapter['dataSaver'] as List<dynamic>?)?.cast<String>() ??
          (chapter['data'] as List<dynamic>?)?.cast<String>() ??
          [];
      final quality = chapter.containsKey('dataSaver') ? 'data-saver' : 'data';
      const cdnBase = 'https://uploads.mangadex.org';
      return pages.map((p) => '$cdnBase/$quality/$hash/$p').toList();
    } catch (e) {
      return [];
    }
  }
}

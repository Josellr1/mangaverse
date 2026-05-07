// lib/services/api_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/manga_model.dart';

class ApiService {
  static const _base = 'https://api.mangadex.org';

  /// Tiempo máximo por petición HTTP
  static const _timeout = Duration(seconds: 15);

  /// Headers estándar
  static Map<String, String> get _headers => {
        'User-Agent': 'MangaVerseApp/1.0 (Android; contact@mangaverse.app)',
        'Accept': 'application/json',
      };

  // ─────────────────────────────────────────────────────────────────────────
  // HELPERS
  // ─────────────────────────────────────────────────────────────────────────

  /// GET con timeout y hasta [maxRetries] reintentos ante errores de red/5xx.
  static Future<http.Response> _get(Uri uri, {int maxRetries = 3}) async {
    Exception? lastError;
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        final res = await http
            .get(uri, headers: _headers)
            .timeout(_timeout);
        // Retry on server errors (5xx)
        if (res.statusCode >= 500 && attempt < maxRetries) {
          await Future.delayed(Duration(milliseconds: 600 * attempt));
          continue;
        }
        return res;
      } on SocketException catch (e) {
        lastError = e;
        await Future.delayed(Duration(milliseconds: 500 * attempt));
      } on http.ClientException catch (e) {
        lastError = e;
        await Future.delayed(Duration(milliseconds: 500 * attempt));
      } catch (e) {
        lastError = Exception(e.toString());
        // Non-retryable errors: timeout, format, etc.
        break;
      }
    }
    throw lastError ?? Exception('Request failed after $maxRetries retries');
  }

  // ─────────────────────────────────────────────────────────────────────────
  // PUBLIC API
  // ─────────────────────────────────────────────────────────────────────────

  /// Busca mangas populares o por título.
  /// [lang]: 'es' | 'en' | null (todos)
  static Future<List<Manga>> searchMangas(
    String query, {
    int limit = 24,
    int offset = 0,
    String? lang,
  }) async {
    try {
      final params = <String, dynamic>{
        if (query.isNotEmpty) 'title': query,
        'limit': '$limit',
        'offset': '$offset',
        'includes[]': ['cover_art', 'author'],
        'order[followedCount]': 'desc',
        'contentRating[]': ['safe', 'suggestive'],
      };
      if (lang == 'es') {
        params['availableTranslatedLanguage[]'] = ['es', 'es-la'];
      } else if (lang == 'en') {
        params['availableTranslatedLanguage[]'] = ['en'];
      }

      final uri = Uri.parse('$_base/manga').replace(queryParameters: params);
      final res = await _get(uri);
      if (res.statusCode != 200) {
        _logError('searchMangas', res.statusCode, res.body);
        return [];
      }
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      final data = json['data'] as List<dynamic>? ?? [];
      return data
          .map((e) => Manga.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _log('searchMangas error: $e');
      return [];
    }
  }

  /// Obtiene el detalle de un manga por ID.
  static Future<Manga?> getManga(String id) async {
    try {
      final uri = Uri.parse('$_base/manga/$id').replace(queryParameters: {
        'includes[]': ['cover_art', 'author', 'artist'],
      });
      final res = await _get(uri);
      if (res.statusCode != 200) {
        _logError('getManga', res.statusCode, res.body);
        return null;
      }
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      return Manga.fromJson(json['data'] as Map<String, dynamic>);
    } catch (e) {
      _log('getManga error: $e');
      return null;
    }
  }

  /// Obtiene capítulos de un manga.
  /// [lang]: 'es' | 'en' | null (todos)
  static Future<List<Chapter>> getChapters(
    String mangaId, {
    String? lang,
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

      final res = await _get(uri);
      if (res.statusCode != 200) {
        _logError('getChapters', res.statusCode, res.body);
        return [];
      }
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      final data = json['data'] as List<dynamic>? ?? [];
      return data
          .map((e) => Chapter.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _log('getChapters error: $e');
      return [];
    }
  }

  /// Obtiene las URLs de páginas de un capítulo vía @home server.
  /// Usa data-saver por defecto para menor consumo de datos.
  static Future<List<String>> getChapterPages(String chapterId,
      {bool dataSaver = true}) async {
    try {
      final uri = Uri.parse('$_base/at-home/server/$chapterId');
      final res = await _get(uri);

      if (res.statusCode != 200) {
        _logError('getChapterPages', res.statusCode, res.body);
        return [];
      }

      final json = jsonDecode(res.body) as Map<String, dynamic>;
      final chapter = json['chapter'] as Map<String, dynamic>;
      final hash = chapter['hash'] as String;

      // Elegir calidad
      final List<String>? saverPages =
          (chapter['dataSaver'] as List<dynamic>?)?.cast<String>();
      final List<String>? fullPages =
          (chapter['data'] as List<dynamic>?)?.cast<String>();

      final pages = (dataSaver ? saverPages : null) ?? fullPages ?? [];
      final quality = (dataSaver && saverPages != null && saverPages.isNotEmpty)
          ? 'data-saver'
          : 'data';

      final cdnBase =
          json['baseUrl'] as String? ?? 'https://uploads.mangadex.org';

      return pages.map((p) => '$cdnBase/$quality/$hash/$p').toList();
    } catch (e) {
      _log('getChapterPages error: $e');
      return [];
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // UTILS
  // ─────────────────────────────────────────────────────────────────────────

  static void _log(String msg) {
    // ignore: avoid_print
    print('[ApiService] $msg');
  }

  static void _logError(String method, int status, String body) {
    final snippet = body.length > 200 ? body.substring(0, 200) : body;
    _log('$method → HTTP $status: $snippet');
  }
}

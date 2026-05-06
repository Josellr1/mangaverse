// lib/services/history_service.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class HistoryEntry {
  final String chapterId;
  final String mangaId;
  final String mangaTitle;
  final String? coverUrl;
  final String chapterTitle;
  final DateTime readAt;

  HistoryEntry({
    required this.chapterId,
    required this.mangaId,
    required this.mangaTitle,
    this.coverUrl,
    required this.chapterTitle,
    required this.readAt,
  });

  Map<String, dynamic> toJson() => {
        'chapterId': chapterId,
        'mangaId': mangaId,
        'mangaTitle': mangaTitle,
        'coverUrl': coverUrl,
        'chapterTitle': chapterTitle,
        'readAt': readAt.toIso8601String(),
      };

  factory HistoryEntry.fromJson(Map<String, dynamic> json) => HistoryEntry(
        chapterId: json['chapterId'] as String,
        mangaId: json['mangaId'] as String? ?? '',
        mangaTitle: json['mangaTitle'] as String? ?? 'Desconocido',
        coverUrl: json['coverUrl'] as String?,
        chapterTitle: json['chapterTitle'] as String? ?? '',
        readAt: DateTime.tryParse(json['readAt'] as String? ?? '') ??
            DateTime.now(),
      );
}

class HistoryService {
  static const _key = 'mv_history';
  static const _maxEntries = 100;

  static Future<List<HistoryEntry>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => HistoryEntry.fromJson(e as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => b.readAt.compareTo(a.readAt));
    } catch (_) {
      return [];
    }
  }

  static Future<void> addEntry(HistoryEntry entry) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = await getHistory();

    // Remove duplicate chapter if already read
    existing.removeWhere((e) => e.chapterId == entry.chapterId);

    // Insert at beginning
    existing.insert(0, entry);

    // Trim to max
    final trimmed = existing.take(_maxEntries).toList();

    await prefs.setString(
      _key,
      jsonEncode(trimmed.map((e) => e.toJson()).toList()),
    );
  }

  static Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  static Future<int> getCount() async {
    final history = await getHistory();
    return history.length;
  }
}

// lib/models/manga_model.dart
class Manga {
  final String id;
  final String title;
  final String? coverUrl;
  final String? description;
  final String? status;
  final int? year;
  final String? author;
  final List<String> tags;

  Manga({
    required this.id,
    required this.title,
    this.coverUrl,
    this.description,
    this.status,
    this.year,
    this.author,
    this.tags = const [],
  });

  factory Manga.fromJson(Map<String, dynamic> json) {
    final attrs = json['attributes'] as Map<String, dynamic>? ?? {};
    final rels = json['relationships'] as List<dynamic>? ?? [];

    // Title: prefer es, es-la, en, or first available
    final titleMap = attrs['title'] as Map<String, dynamic>? ?? {};
    final title = titleMap['es'] ??
        titleMap['es-la'] ??
        titleMap['en'] ??
        (titleMap.isNotEmpty ? titleMap.values.first : 'Sin título');

    // Description
    final descMap = attrs['description'] as Map<String, dynamic>? ?? {};
    final description = descMap['es'] ??
        descMap['es-la'] ??
        descMap['en'] ??
        (descMap.isNotEmpty ? descMap.values.first : null);

    // Cover art
    final coverRel = rels.firstWhere(
      (r) => r['type'] == 'cover_art',
      orElse: () => null,
    );
    String? coverUrl;
    if (coverRel != null && coverRel['attributes'] != null) {
      final fileName = coverRel['attributes']['fileName'];
      if (fileName != null) {
        coverUrl =
            'https://uploads.mangadex.org/covers/${json['id']}/$fileName.256.jpg';
      }
    }

    // Author
    final authorRel = rels.firstWhere(
      (r) => r['type'] == 'author',
      orElse: () => null,
    );
    final author = authorRel?['attributes']?['name'];

    // Tags (en)
    final tagsRaw = attrs['tags'] as List<dynamic>? ?? [];
    final tags = tagsRaw
        .map((t) => t['attributes']?['name']?['en'] as String?)
        .whereType<String>()
        .take(4)
        .toList();

    return Manga(
      id: json['id'] as String,
      title: title.toString(),
      coverUrl: coverUrl,
      description: description?.toString(),
      status: attrs['status'] as String?,
      year: attrs['year'] as int?,
      author: author as String?,
      tags: tags,
    );
  }

  String get highResCoverUrl {
    if (coverUrl == null) return '';
    return coverUrl!.replaceAll('.256.jpg', '');
  }
}

class Chapter {
  final String id;
  final String? chapterNumber;
  final String? title;
  final String language;
  final DateTime? publishedAt;
  final String? scanlationGroup;

  Chapter({
    required this.id,
    this.chapterNumber,
    this.title,
    required this.language,
    this.publishedAt,
    this.scanlationGroup,
  });

  factory Chapter.fromJson(Map<String, dynamic> json) {
    final attrs = json['attributes'] as Map<String, dynamic>? ?? {};
    final rels = json['relationships'] as List<dynamic>? ?? [];

    final groupRel = rels.firstWhere(
      (r) => r['type'] == 'scanlation_group',
      orElse: () => null,
    );

    DateTime? publishedAt;
    if (attrs['publishAt'] != null) {
      publishedAt = DateTime.tryParse(attrs['publishAt'] as String);
    }

    return Chapter(
      id: json['id'] as String,
      chapterNumber: attrs['chapter'] as String?,
      title: attrs['title'] as String?,
      language: attrs['translatedLanguage'] as String? ?? 'en',
      publishedAt: publishedAt,
      scanlationGroup: groupRel?['attributes']?['name'] as String?,
    );
  }

  String get displayTitle {
    final num = chapterNumber != null ? 'Cap. $chapterNumber' : 'Oneshot';
    final extra = title != null && title!.isNotEmpty ? ' — $title' : '';
    return '$num$extra';
  }

  String get langFlag {
    if (language == 'es' || language == 'es-la') return '🇪🇸';
    if (language == 'en') return '🇺🇸';
    return language.toUpperCase();
  }
}

import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final params = {
    'limit': '5',
    'includes[]': ['cover_art', 'author'],
  };
  final uri = Uri.parse('https://api.mangadex.org/manga').replace(queryParameters: params);
  print(uri);
  final res = await http.get(uri, headers: {
    'User-Agent': 'MangaVerseApp/1.0 (https://github.com/Josellr1/mangaverse)',
  });
  print(res.statusCode);
  if (res.statusCode == 200) {
    final json = jsonDecode(res.body);
    print((json['data'] as List).length);
  } else {
    print(res.body);
  }
}

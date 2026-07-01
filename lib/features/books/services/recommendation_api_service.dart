import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

/// Korisnikova knjiga koju je označio ("ref")
class RefEntry {
  final String bookId;
  final bool liked;
  final String status;

  const RefEntry({
    required this.bookId,
    this.liked = false,
    this.status = 'none',
  });

  Map<String, dynamic> toJson() => {
    'book_id': bookId,
    'liked': liked,
    'status': status,
  };
}

/// Jedna preporučena knjiga koju vraća servis
class RecommendedBook {
  final String id;
  final String title;
  final String author;
  final List<String> genres;
  final double avgRating;
  final int numRatings;
  final double score;

  RecommendedBook({
    required this.id,
    required this.title,
    required this.author,
    required this.genres,
    required this.avgRating,
    required this.numRatings,
    required this.score,
  });

  factory RecommendedBook.fromJson(Map<String, dynamic> j) => RecommendedBook(
    id: j['id'] as String,
    title: j['title'] as String,
    author: j['author'] as String? ?? '',
    genres: (j['genres'] as List<dynamic>? ?? []).cast<String>(),
    avgRating: (j['avg_rating'] as num? ?? 0).toDouble(),
    numRatings: (j['num_ratings'] as num? ?? 0).toInt(),
    score: (j['score'] as num? ?? 0).toDouble(),
  );
}

class RecommendationApiService {
  final String baseUrl;

  /// Vrijeme čekanja nakon zadnje promjene prije slanja zahtjeva
  final Duration debounce;

  Timer? _debounceTimer;
  final http.Client _client = http.Client();

  RecommendationApiService({
    required this.baseUrl,
    this.debounce = const Duration(milliseconds: 400),
  });

  // Pozovi pri svakoj promjeni stanja
  Future<List<RecommendedBook>> refresh(List<RefEntry> refs, {int limit = 50}) {
    _debounceTimer?.cancel();
    final completer = Completer<List<RecommendedBook>>();
    _debounceTimer = Timer(debounce, () async {
      try {
        final result = await _fetch(refs, limit);
        if (!completer.isCompleted) completer.complete(result);
      } catch (e) {
        if (!completer.isCompleted) completer.completeError(e);
      }
    });
    return completer.future;
  }

  Future<List<RecommendedBook>> fetchNow(
    List<RefEntry> refs, {
    int limit = 50,
  }) => _fetch(refs, limit);

  Future<List<RecommendedBook>> _fetch(List<RefEntry> refs, int limit) async {
    if (refs.isEmpty) return [];

    final uri = Uri.parse('$baseUrl/recommendations');
    final body = jsonEncode({
      'limit': limit,
      'entries': refs.map((r) => r.toJson()).toList(),
    });

    final resp = await _client
        .post(uri, headers: {'Content-Type': 'application/json'}, body: body)
        .timeout(const Duration(seconds: 15));

    if (resp.statusCode != 200) {
      throw Exception(
        'Recommender servis greška ${resp.statusCode}: ${resp.body}',
      );
    }

    final decoded = jsonDecode(resp.body) as Map<String, dynamic>;
    final list = (decoded['recommendations'] as List<dynamic>? ?? []);
    return list
        .map((e) => RecommendedBook.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  void dispose() {
    _debounceTimer?.cancel();
    _client.close();
  }
}

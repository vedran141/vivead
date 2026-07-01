import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/book_model.dart';
import 'book_cache.dart';
import 'recommendation_api_service.dart';

const String kRecommenderBaseUrl = 'http://10.0.2.2:8000';

// Servis za dohvat preporuka knjiga za korisnika
class RecommendationService {
  final BookCache _cache = BookCache();
  final RecommendationApiService _api = RecommendationApiService(
    baseUrl: kRecommenderBaseUrl,
  );

  Future<List<BookModel>> getRecommendations(
    String uid, {
    int limit = 30,
  }) async {
    if (!_cache.loaded) await _cache.load();
    if (_cache.books.isEmpty) return [];

    final refs = await _fetchRefs(uid);
    if (refs.isEmpty) return [];

    final recs = await _api.fetchNow(refs, limit: limit);
    return _mapToBookModels(recs);
  }

  Future<List<BookModel>> refresh(String uid, {int limit = 30}) async {
    if (!_cache.loaded) await _cache.load();
    final refs = await _fetchRefs(uid);
    if (refs.isEmpty) return [];
    final recs = await _api.refresh(refs, limit: limit);
    return _mapToBookModels(recs);
  }

  List<BookModel> _mapToBookModels(List<RecommendedBook> recs) {
    final byId = _indexById();
    final out = <BookModel>[];
    for (final r in recs) {
      final book = byId[r.id];
      if (book != null) out.add(book);
    }
    return out;
  }

  Future<List<RefEntry>> _fetchRefs(String uid) async {
    final snap = await FirebaseFirestore.instance
        .collection('userBooks')
        .doc(uid)
        .collection('books')
        .get();

    return snap.docs.map((doc) {
      final d = doc.data();
      return RefEntry(
        bookId: doc.id,
        liked: (d['liked'] as bool?) ?? false,
        status: (d['status'] as String?) ?? 'none',
      );
    }).toList();
  }

  Map<String, BookModel>? _idIndex;

  Map<String, BookModel> _indexById() {
    return _idIndex ??= {for (final b in _cache.books) b.id: b};
  }

  /// Knjige po statusu čitanja.
  Future<List<BookModel>> booksByStatus(String uid, String status) async {
    if (!_cache.loaded) await _cache.load();
    final snap = await FirebaseFirestore.instance
        .collection('userBooks')
        .doc(uid)
        .collection('books')
        .where('status', isEqualTo: status)
        .get();
    final ids = snap.docs.map((d) => d.id).toSet();
    return _cache.books.where((b) => ids.contains(b.id)).toList();
  }

  Future<bool> hasEnoughData(String uid) async {
    final snap = await FirebaseFirestore.instance
        .collection('userBooks')
        .doc(uid)
        .collection('books')
        .limit(1)
        .get();
    return snap.docs.isNotEmpty;
  }

  void dispose() => _api.dispose();
}

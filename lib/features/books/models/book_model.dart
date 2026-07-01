import 'package:cloud_firestore/cloud_firestore.dart';

class BookModel {
  final String id;
  final String title;
  final String titleLower;
  final String author;
  final String authorLower;
  final List<String> genres;
  final String description;
  final double avgRating;
  final int numRatings;
  final String? coverUrl;
  final String? goodreadsUrl;

  const BookModel({
    required this.id,
    required this.title,
    required this.titleLower,
    required this.author,
    required this.authorLower,
    required this.genres,
    required this.description,
    required this.avgRating,
    required this.numRatings,
    this.coverUrl,
    this.goodreadsUrl,
  });

  String getCoverUrl() {
    return coverUrl ?? '';
  }

  factory BookModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return BookModel(
      id: doc.id,
      title: data['title'] ?? '',
      titleLower: data['titleLower'] ?? '',
      author: data['author'] ?? '',
      authorLower: data['authorLower'] ?? '',
      genres: List<String>.from(data['genres'] ?? []),
      description: data['description'] ?? '',
      avgRating: (data['avgRating'] ?? 0).toDouble(),
      numRatings: data['numRatings'] ?? 0,
      coverUrl: data['coverUrl'],
      goodreadsUrl: data['goodreadsUrl'],
    );
  }
}

import '../models/book_model.dart';

class BookRanking {
  const BookRanking._();

  static List<BookModel> popular(
    List<BookModel> books, {
    int? limit,
    int minRatings = 1000000,
    double bayesPrior = 1000,
  }) {
    final eligible = books.where((b) => b.numRatings >= minRatings).toList();
    final pool = eligible.isNotEmpty ? eligible : books;

    final rated = pool.where((b) => b.numRatings > 0).toList();
    final globalAvg = rated.isEmpty
        ? 0.0
        : rated.fold<double>(0, (acc, b) => acc + b.avgRating) / rated.length;

    double bayes(BookModel b) {
      final v = b.numRatings.toDouble();
      return (v / (v + bayesPrior)) * b.avgRating +
          (bayesPrior / (v + bayesPrior)) * globalAvg;
    }

    final sorted = List<BookModel>.from(pool)
      ..sort((a, b) => bayes(b).compareTo(bayes(a)));

    if (limit != null && limit < sorted.length) {
      return sorted.sublist(0, limit);
    }
    return sorted;
  }
}

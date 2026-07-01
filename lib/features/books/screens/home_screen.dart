import 'package:flutter/material.dart';
import '../../books/models/book_model.dart';
import '../../books/widgets/book_card.dart';
import '../../books/services/book_cache.dart';
import '../../search/screens/genre_books_screen.dart';
import '../../books/screens/book_detail_screen.dart';
import '../../books/widgets/genre_card.dart';
import '../../books/widgets/book_grid_delegate.dart';
import '../../books/services/book_ranking.dart';

const List<String> _popularGenres = [
  'Fiction',
  'Fantasy',
  'Mystery',
  'Thriller',
  'Romance',
  'Science Fiction',
  'Horror',
  'Historical Fiction',
  'Classics',
  'Adventure',
  'Biography',
  'Self Help',
  'Poetry',
  'Graphic Novels',
  'Crime',
  'Humor',
  'Drama',
  'Dystopia',
  'Memoir',
  'Nonfiction',
];

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cache = BookCache();

    final books = BookRanking.popular(
      cache.books,
      limit: 30,
      minRatings: 1000000,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: CustomScrollView(
        slivers: [
          // Popular Books sekcija
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          _SectionHeader(title: 'Popular books'),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid(
              delegate: SliverChildBuilderDelegate(
                (context, index) => BookCard(
                  book: books[index],
                  onTap: () => _openBook(context, books[index]),
                ),
                childCount: books.length,
              ),
              gridDelegate: kBookGridDelegate,
            ),
          ),

          // Popular Genres sekcija
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
          _SectionHeader(title: 'Popular genres'),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              16,
              8,
              16,
              MediaQuery.of(context).padding.bottom + 80,
            ),
            sliver: SliverGrid(
              delegate: SliverChildBuilderDelegate((context, index) {
                final genre = _popularGenres[index];
                return GenreCard(
                  genre: genre,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          GenreBooksScreen(genre: genre, allBooks: cache.books),
                    ),
                  ),
                );
              }, childCount: _popularGenres.length),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 2.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openBook(BuildContext context, BookModel book) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => BookDetailScreen(book: book)),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

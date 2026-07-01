import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../books/models/book_model.dart';
import '../../books/widgets/book_card.dart';
import '../../books/screens/book_detail_screen.dart';
import 'genre_books_screen.dart';
import '../../books/services/book_cache.dart';
import '../../books/widgets/genre_card.dart';
import '../../books/widgets/book_grid_delegate.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  final _cache = BookCache();

  String _query = '';
  List<BookModel> _results = [];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _search(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) {
      setState(() => _results = []);
      return;
    }
    setState(() {
      _results = _cache.books
          .where((b) => b.titleLower.contains(q) || b.authorLower.contains(q))
          .take(50)
          .toList();
    });
  }

  void _openBook(BookModel book) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => BookDetailScreen(book: book)),
    );
  }

  void _openGenre(String genre) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GenreBooksScreen(genre: genre, allBooks: _cache.books),
      ),
    );
  }

  Widget _emptyGenresState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.favorite_outline,
            size: 48,
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 12),
          Text(
            'No favorite genres yet',
            style: TextStyle(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add genres in your Profile section',
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isTyping = _query.isNotEmpty;
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(title: const Text('Search')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Traka za pretraživanje
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: 'Title, author...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: isTyping
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _controller.clear();
                          setState(() {
                            _query = '';
                            _results = [];
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: (val) {
                setState(() => _query = val);
                _search(val);
              },
            ),
          ),

          // Žanr kartice
          if (!isTyping)
            Expanded(
              child: uid == null
                  ? _emptyGenresState(context)
                  : StreamBuilder<DocumentSnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('users')
                          .doc(uid)
                          .snapshots(),
                      builder: (context, snapshot) {
                        final data =
                            snapshot.data?.data() as Map<String, dynamic>?;
                        final userGenres = List<String>.from(
                          data?['favoriteGenres'] ?? [],
                        );

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                              child: Text(
                                'Your favourite genres',
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ),
                            Expanded(
                              child: userGenres.isEmpty
                                  ? _emptyGenresState(context)
                                  : GridView.builder(
                                      padding: EdgeInsets.fromLTRB(
                                        16,
                                        0,
                                        16,
                                        MediaQuery.of(context).padding.bottom +
                                            80,
                                      ),
                                      gridDelegate:
                                          const SliverGridDelegateWithFixedCrossAxisCount(
                                            crossAxisCount: 2,
                                            crossAxisSpacing: 12,
                                            mainAxisSpacing: 12,
                                            childAspectRatio: 2.2,
                                          ),
                                      itemCount: userGenres.length,
                                      itemBuilder: (context, index) =>
                                          GenreCard(
                                            genre: userGenres[index],
                                            onTap: () =>
                                                _openGenre(userGenres[index]),
                                          ),
                                    ),
                            ),
                          ],
                        );
                      },
                    ),
            ),

          // Rezultati pretrage
          if (isTyping)
            Expanded(
              child: _results.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 56,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.3),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No results for "$_query"',
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                    )
                  : GridView.builder(
                      padding: EdgeInsets.fromLTRB(
                        16,
                        16,
                        16,
                        MediaQuery.of(context).padding.bottom + 80,
                      ),
                      gridDelegate: kBookGridDelegate,
                      itemCount: _results.length,
                      itemBuilder: (context, index) => BookCard(
                        book: _results[index],
                        onTap: () => _openBook(_results[index]),
                      ),
                    ),
            ),
        ],
      ),
    );
  }
}

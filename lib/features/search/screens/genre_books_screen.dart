import 'package:flutter/material.dart';
import '../../books/models/book_model.dart';
import '../../books/widgets/book_card.dart';
import '../../books/screens/book_detail_screen.dart';
import '../../books/widgets/book_grid_delegate.dart';

class GenreBooksScreen extends StatefulWidget {
  final String genre;
  final List<BookModel> allBooks;

  const GenreBooksScreen({
    required this.genre,
    required this.allBooks,
    super.key,
  });

  @override
  State<GenreBooksScreen> createState() => _GenreBooksScreenState();
}

class _GenreBooksScreenState extends State<GenreBooksScreen> {
  final TextEditingController _controller = TextEditingController();
  String _query = '';

  List<BookModel> get _filtered {
    final genreBooks = widget.allBooks
        .where((b) => b.genres.contains(widget.genre))
        .toList();
    if (_query.trim().isEmpty) return genreBooks;
    final q = _query.trim().toLowerCase();
    return genreBooks
        .where((b) => b.titleLower.contains(q) || b.authorLower.contains(q))
        .toList();
  }

  void _openBook(BuildContext context, BookModel book) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => BookDetailScreen(book: book)),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final books = _filtered;

    return Scaffold(
      appBar: AppBar(title: Text(widget.genre)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: 'Search within genre...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _controller.clear();
                          setState(() => _query = '');
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
              onChanged: (val) => setState(() => _query = val),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${books.length} books',
                style: TextStyle(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.5),
                  fontSize: 13,
                ),
              ),
            ),
          ),
          Expanded(
            child: books.isEmpty
                ? Center(
                    child: Text(
                      'No results found',
                      style: TextStyle(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: kBookGridDelegate,
                    itemCount: books.length,
                    itemBuilder: (context, index) => BookCard(
                      book: books[index],
                      onTap: () => _openBook(context, books[index]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

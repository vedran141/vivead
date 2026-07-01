import 'package:flutter/material.dart';
import '../../books/models/book_model.dart';
import '../../books/widgets/book_card.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../books/screens/book_detail_screen.dart';
import '../../books/widgets/book_grid_delegate.dart';

class FavoritesScreen extends StatelessWidget {
  final String userId;
  const FavoritesScreen({required this.userId, super.key});

  Future<List<BookModel>> _fetchLikedBooks(
    List<QueryDocumentSnapshot> docs,
  ) async {
    final List<BookModel> books = [];
    for (final doc in docs) {
      final bookDoc = await FirebaseFirestore.instance
          .collection('books')
          .doc(doc.id)
          .get();
      if (bookDoc.exists) books.add(BookModel.fromFirestore(bookDoc));
    }
    return books;
  }

  void _openBook(BuildContext context, BookModel book) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => BookDetailScreen(book: book)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Favourite books')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('userBooks')
            .doc(userId)
            .collection('books')
            .where('liked', isEqualTo: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.favorite_outline,
                    size: 64,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'You don\'t have any favourite books yet',
                    style: TextStyle(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.5),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            );
          }

          return FutureBuilder<List<BookModel>>(
            future: _fetchLikedBooks(docs),
            builder: (context, bookSnapshot) {
              if (!bookSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final books = bookSnapshot.data!;

              return GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: kBookGridDelegate,
                itemCount: books.length,
                itemBuilder: (context, index) => BookCard(
                  book: books[index],
                  onTap: () => _openBook(context, books[index]),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

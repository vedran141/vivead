import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../books/models/book_model.dart';
import '../../books/widgets/book_card.dart';
import '../../books/screens/book_detail_screen.dart';
import '../../books/services/book_cache.dart';
import '../../books/services/recommendation_service.dart';
import '../../books/models/reading_status.dart';
import '../../books/widgets/book_grid_delegate.dart';

enum _LibraryTab { recommended, wantToRead, reading, read }

extension _LibraryTabExt on _LibraryTab {
  String get label {
    switch (this) {
      case _LibraryTab.recommended:
        return 'For You';
      case _LibraryTab.wantToRead:
        return 'Want to Read';
      case _LibraryTab.reading:
        return 'Reading';
      case _LibraryTab.read:
        return 'Read';
    }
  }

  ReadingStatus get readingStatus {
    switch (this) {
      case _LibraryTab.recommended:
        return ReadingStatus.none; // ne koristi se
      case _LibraryTab.wantToRead:
        return ReadingStatus.wantToRead;
      case _LibraryTab.reading:
        return ReadingStatus.reading;
      case _LibraryTab.read:
        return ReadingStatus.read;
    }
  }
}

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final RecommendationService _service = RecommendationService();
  final BookCache _cache = BookCache();

  _LibraryTab _tab = _LibraryTab.recommended;

  List<BookModel> _recommended = [];
  bool _loadingRecommended = true;

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _loadRecommended();
  }

  Future<void> _loadRecommended() async {
    final uid = _uid;
    if (uid == null) {
      setState(() {
        _loadingRecommended = false;
        _recommended = [];
      });
      return;
    }

    setState(() => _loadingRecommended = true);
    final result = await _service.getRecommendations(uid, limit: 30);
    if (!mounted) return;
    setState(() {
      _recommended = result;
      _loadingRecommended = false;
    });
  }

  void _selectTab(_LibraryTab tab) {
    if (tab == _tab) return;
    setState(() => _tab = tab);
  }

  void _openBook(BookModel book) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => BookDetailScreen(book: book)),
    ).then((_) {
      if (_tab == _LibraryTab.recommended) _loadRecommended();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Your Library')),
      body: Column(
        children: [
          _TabBar(selected: _tab, onSelect: _selectTab),
          const Divider(height: 1),
          Expanded(
            child: _tab == _LibraryTab.recommended
                ? _buildRecommendedBody()
                : _buildStatusBody(),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendedBody() {
    if (_loadingRecommended) {
      return const Center(child: CircularProgressIndicator());
    }
    return RefreshIndicator(
      onRefresh: _loadRecommended,
      child: _recommended.isEmpty
          ? _EmptyState(tab: _tab)
          : _BookGrid(
              books: _recommended,
              showRecommendedHeader: true,
              onTapBook: _openBook,
            ),
    );
  }

  Widget _buildStatusBody() {
    final uid = _uid;
    if (uid == null) return _EmptyState(tab: _tab);

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('userBooks')
          .doc(uid)
          .collection('books')
          .where('status', isEqualTo: _tab.readingStatus.firestoreValue)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data?.docs ?? [];

        final ids = docs.map((d) => d.id).toSet();
        final books = _cache.books.where((b) => ids.contains(b.id)).toList();

        if (books.isEmpty) return _EmptyState(tab: _tab);

        return _BookGrid(
          books: books,
          showRecommendedHeader: false,
          onTapBook: _openBook,
        );
      },
    );
  }
}

// Zajednički prikaz mreže knjiga za sve tabove (za "For You" prikazuje i podnaslov iznad mreže)
class _BookGrid extends StatelessWidget {
  final List<BookModel> books;
  final bool showRecommendedHeader;
  final ValueChanged<BookModel> onTapBook;

  const _BookGrid({
    required this.books,
    required this.showRecommendedHeader,
    required this.onTapBook,
  });

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        if (showRecommendedHeader) ...[
          const SliverToBoxAdapter(child: SizedBox(height: 12)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: Text(
                'Based on what you\'ve read and liked',
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ),
          ),
        ] else
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            16,
            4,
            16,
            MediaQuery.of(context).padding.bottom + 80,
          ),
          sliver: SliverGrid(
            delegate: SliverChildBuilderDelegate(
              (context, index) => BookCard(
                book: books[index],
                onTap: () => onTapBook(books[index]),
              ),
              childCount: books.length,
            ),
            gridDelegate: kBookGridDelegate,
          ),
        ),
      ],
    );
  }
}

// Bar s karticama na vrhu ekrana
class _TabBar extends StatelessWidget {
  final _LibraryTab selected;
  final ValueChanged<_LibraryTab> onSelect;

  const _TabBar({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        children: _LibraryTab.values.map((tab) {
          final isActive = tab == selected;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: GestureDetector(
              onTap: () => onSelect(tab),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isActive
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isActive
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.15),
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  tab.label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isActive
                        ? Theme.of(context).colorScheme.onPrimary
                        : Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// Empty state prikaz kad nema knjiga u odabranoj kartici prikazuje ikonu i poruku
class _EmptyState extends StatelessWidget {
  final _LibraryTab tab;
  const _EmptyState({required this.tab});

  String get _message {
    switch (tab) {
      case _LibraryTab.recommended:
        return 'Add some books to your library and we\'ll recommend more like them';
      case _LibraryTab.wantToRead:
        return 'Books you mark as "Want to Read" will appear here';
      case _LibraryTab.reading:
        return 'Books you\'re currently reading will appear here';
      case _LibraryTab.read:
        return 'Books you\'ve finished will appear here';
    }
  }

  IconData get _icon {
    switch (tab) {
      case _LibraryTab.recommended:
        return Icons.auto_stories_outlined;
      case _LibraryTab.wantToRead:
        return Icons.bookmark_outline;
      case _LibraryTab.reading:
        return Icons.menu_book_outlined;
      case _LibraryTab.read:
        return Icons.check_circle_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.2),
        Icon(
          _icon,
          size: 64,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
        ),
        const SizedBox(height: 16),
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              _message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.5),
                fontSize: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

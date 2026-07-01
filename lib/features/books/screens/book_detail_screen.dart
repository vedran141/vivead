import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/book_model.dart';
import '../services/book_cache.dart';
import '../../search/screens/genre_books_screen.dart';
import '../models/reading_status.dart';

class BookDetailScreen extends StatefulWidget {
  final BookModel book;
  const BookDetailScreen({required this.book, super.key});

  @override
  State<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<BookDetailScreen> {
  bool _liked = false;
  ReadingStatus _status = ReadingStatus.none;
  bool _loading = true;

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _loadUserBookData();
  }

  Future<void> _loadUserBookData() async {
    if (_uid == null) return;
    final doc = await FirebaseFirestore.instance
        .collection('userBooks')
        .doc(_uid)
        .collection('books')
        .doc(widget.book.id)
        .get();

    if (doc.exists) {
      final data = doc.data()!;
      setState(() {
        _liked = data['liked'] ?? false;
        _status = ReadingStatusX.fromString(data['status']);
      });
    }
    setState(() => _loading = false);
  }

  Future<void> _saveToFirestore() async {
    if (_uid == null) return;
    final ref = FirebaseFirestore.instance
        .collection('userBooks')
        .doc(_uid)
        .collection('books')
        .doc(widget.book.id);

    if (_status == ReadingStatus.none && !_liked) {
      await ref.delete();
    } else {
      await ref.set({
        'liked': _liked,
        'status': _status.firestoreValue,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> _toggleLike() async {
    setState(() => _liked = !_liked);
    await _saveToFirestore();
  }

  Future<void> _setStatus(ReadingStatus status) async {
    setState(() => _status = status == _status ? ReadingStatus.none : status);
    await _saveToFirestore();
  }

  @override
  Widget build(BuildContext context) {
    final book = widget.book;
    final colorScheme = Theme.of(context).colorScheme;
    final hasCover = book.coverUrl != null && book.coverUrl!.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        actions: [
          if (!_loading)
            IconButton(
              onPressed: _toggleLike,
              icon: Icon(
                _liked ? Icons.favorite : Icons.favorite_outline,
                color: _liked ? Colors.red : null,
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Pozadina s naslovnicom i gradijentom
            SizedBox(
              height: 280,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Pozadina s naslovnicom ili primarna boja ako nema naslovnice
                  if (hasCover)
                    CachedNetworkImage(
                      imageUrl: book.coverUrl!,
                      fit: BoxFit.cover,
                      errorWidget: (_, _, _) =>
                          Container(color: colorScheme.primary),
                    )
                  else
                    Container(color: colorScheme.primary),

                  // Gradijent na pozadini
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.3),
                          colorScheme.surface.withValues(alpha: 0.95),
                        ],
                        stops: const [0.3, 1.0],
                      ),
                    ),
                  ),

                  // Naslovnica knjige (ako postoji) ili placeholder ikona knjige
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: hasCover
                            ? CachedNetworkImage(
                                imageUrl: book.coverUrl!,
                                height: 180,
                                fit: BoxFit.cover,
                                errorWidget: (_, _, _) => Container(
                                  height: 180,
                                  width: 120,
                                  color: colorScheme.primary,
                                  child: Icon(
                                    Icons.book,
                                    size: 48,
                                    color: colorScheme.onPrimary.withValues(
                                      alpha: 0.5,
                                    ),
                                  ),
                                ),
                              )
                            : Container(
                                height: 180,
                                width: 120,
                                color: colorScheme.primary,
                                child: Icon(
                                  Icons.book,
                                  size: 48,
                                  color: colorScheme.onPrimary.withValues(
                                    alpha: 0.5,
                                  ),
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Podaci o knjizi (naslov, autor, ocjena, status, žanrovi, opis)
            Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                16,
                20,
                MediaQuery.of(context).padding.bottom + 32,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Naslov i autor knjige
                  Text(
                    book.title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    book.author,
                    style: TextStyle(
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Ocjena
                  Row(
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        color: Colors.amber,
                        size: 20,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        book.avgRating.toStringAsFixed(1),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '(${_formatCount(book.numRatings)} ratings)',
                        style: TextStyle(
                          color: colorScheme.onSurface.withValues(alpha: 0.5),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Status gumbovi
                  if (!_loading) ...[
                    Text(
                      'Status',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children:
                          [
                            ReadingStatus.wantToRead,
                            ReadingStatus.reading,
                            ReadingStatus.read,
                          ].map((status) {
                            final isActive = _status == status;
                            return Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: _StatusButton(
                                  label: status.label,
                                  icon: status.icon,
                                  isActive: isActive,
                                  onTap: () => _setStatus(status),
                                ),
                              ),
                            );
                          }).toList(),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Žanrovi
                  if (book.genres.isNotEmpty) ...[
                    Text(
                      'Genres',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: book.genres.map((genre) {
                        return GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => GenreBooksScreen(
                                genre: genre,
                                allBooks: BookCache().books,
                              ),
                            ),
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.surface,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: colorScheme.onSurface.withValues(
                                  alpha: 0.15,
                                ),
                              ),
                            ),
                            child: Text(
                              genre,
                              style: TextStyle(
                                fontSize: 12,
                                color: colorScheme.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Opis
                  if (book.description.isNotEmpty) ...[
                    Text(
                      'Description',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _ExpandableDescription(description: book.description),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Formatiranje broja ocjena (npr. 1000 -> 1k, 1000000 -> 1M)
  String _formatCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(0)}k';
    return count.toString();
  }
}

// Widget za status gumbove
class _StatusButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const _StatusButton({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isActive
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive
                ? Theme.of(context).colorScheme.primary
                : Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 20,
              color: isActive
                  ? Theme.of(context).colorScheme.onPrimary
                  : Theme.of(context).colorScheme.onSurface,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: isActive
                    ? Theme.of(context).colorScheme.onPrimary
                    : Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// "Show more / Show less" gumb
class _ExpandableDescription extends StatefulWidget {
  final String description;
  const _ExpandableDescription({required this.description});

  @override
  State<_ExpandableDescription> createState() => _ExpandableDescriptionState();
}

class _ExpandableDescriptionState extends State<_ExpandableDescription> {
  bool _expanded = false;

  bool get _isShort => widget.description.length < 300;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.description,
          maxLines: _isShort || _expanded ? null : 4,
          overflow: _isShort || _expanded
              ? TextOverflow.visible
              : TextOverflow.ellipsis,
          style: TextStyle(
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.8),
            height: 1.5,
          ),
        ),
        if (!_isShort) ...[
          const SizedBox(height: 4),
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Text(
              _expanded ? 'Show less' : 'Show more',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// features/user/screens/favorite_genres_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FavoriteGenresScreen extends StatefulWidget {
  final String userId;
  const FavoriteGenresScreen({required this.userId, super.key});

  @override
  State<FavoriteGenresScreen> createState() => _FavoriteGenresScreenState();
}

class _FavoriteGenresScreenState extends State<FavoriteGenresScreen> {
  List<String> _allGenres = [];
  List<String> _selected = [];
  String _searchFilter = '';
  String? _letterFilter;
  bool _showOnlySelected = false;
  bool _loading = true;
  bool _saving = false;

  final List<String> _alphabet = [
    'A',
    'B',
    'C',
    'D',
    'E',
    'F',
    'G',
    'H',
    'I',
    'J',
    'K',
    'L',
    'M',
    'N',
    'O',
    'P',
    'Q',
    'R',
    'S',
    'T',
    'U',
    'V',
    'W',
    'X',
    'Y',
    'Z',
    '#',
  ];

  final ScrollController _listScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _listScrollController.dispose();
    super.dispose();
  }

  void _scrollToTop() {
    if (_listScrollController.hasClients) {
      _listScrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _loadData() async {
    final genresDoc = await FirebaseFirestore.instance
        .collection('metadata')
        .doc('genres')
        .get();
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .get();

    setState(() {
      _allGenres = List<String>.from(genresDoc.data()?['all'] ?? []);
      _selected = List<String>.from(userDoc.data()?['favoriteGenres'] ?? []);
      _loading = false;
    });
  }

  Future<void> _saveGenres() async {
    setState(() => _saving = true);
    await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .update({'favoriteGenres': _selected});
    setState(() => _saving = false);

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Genres saved!')));
      Navigator.pop(context);
    }
  }

  void _toggleGenre(String genre) {
    setState(() {
      _selected.contains(genre)
          ? _selected.remove(genre)
          : _selected.add(genre);
    });
  }

  void _setLetterFilter(String? letter) {
    setState(() => _letterFilter = letter);
    _scrollToTop();
  }

  void _setShowOnlySelected(bool val) {
    setState(() => _showOnlySelected = val);
    _scrollToTop();
  }

  void _setSearchFilter(String val) {
    setState(() => _searchFilter = val);
    _scrollToTop();
  }

  void _clearSelected() {
    setState(() => _selected.clear());
    _scrollToTop();
  }

  List<String> get _filteredGenres {
    return _allGenres.where((g) {
      if (_searchFilter.isNotEmpty &&
          !g.toLowerCase().contains(_searchFilter.toLowerCase())) {
        return false;
      }
      if (_letterFilter != null) {
        if (_letterFilter == '#') {
          if (RegExp(r'[a-zA-Z]').hasMatch(g[0])) return false;
        } else {
          if (!g.toUpperCase().startsWith(_letterFilter!)) return false;
        }
      }
      if (_showOnlySelected && !_selected.contains(g)) return false;
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredGenres;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Favourite genres'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _saveGenres,
            child: _saving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(
                    'Save',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Traka za pretraživanje
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search genres...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchFilter.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () => _setSearchFilter(''),
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
                    onChanged: _setSearchFilter,
                  ),
                ),

                // Filter po abecedi (A-Z, #)
                SizedBox(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: _alphabet.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return _LetterChip(
                          label: 'All',
                          isActive: _letterFilter == null,
                          onTap: () => _setLetterFilter(null),
                        );
                      }
                      final letter = _alphabet[index - 1];
                      final isActive = _letterFilter == letter;
                      return _LetterChip(
                        label: letter,
                        isActive: isActive,
                        onTap: () => _setLetterFilter(isActive ? null : letter),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 4),

                // Info
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  child: Row(
                    children: [
                      Text(
                        'Selected: ${_selected.length}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Show only selected',
                        style: TextStyle(
                          fontSize: 13,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Switch(
                        value: _showOnlySelected,
                        onChanged: _setShowOnlySelected,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      if (_selected.isNotEmpty) ...[
                        const SizedBox(width: 4),
                        TextButton(
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          onPressed: _clearSelected,
                          child: const Text(
                            'Clear',
                            style: TextStyle(color: Colors.red, fontSize: 13),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const Divider(height: 1),

                // Lista žanrova
                Expanded(
                  child: filtered.isEmpty
                      ? Center(
                          child: Text(
                            'No genres available for this filter',
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.5),
                            ),
                          ),
                        )
                      : ListView.builder(
                          controller: _listScrollController,
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final genre = filtered[index];
                            final isSelected = _selected.contains(genre);

                            return CheckboxListTile(
                              value: isSelected,
                              onChanged: (_) => _toggleGenre(genre),
                              title: Text(genre),
                              activeColor: Theme.of(
                                context,
                              ).colorScheme.primary,
                              controlAffinity: ListTileControlAffinity.trailing,
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}

class _LetterChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _LetterChip({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.symmetric(horizontal: 3),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isActive
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive
                ? Theme.of(context).colorScheme.primary
                : Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.15),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isActive
                ? Theme.of(context).colorScheme.onPrimary
                : Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}

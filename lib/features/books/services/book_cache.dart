import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/book_model.dart';

class BookCache {
  static final BookCache _instance = BookCache._internal();
  factory BookCache() => _instance;
  BookCache._internal();

  List<BookModel> books = [];
  bool loaded = false;
  bool loading = false;

  Future<void> load() async {
    if (loaded || loading) return;
    loading = true;
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('books')
          .get();
      books = snapshot.docs.map((doc) => BookModel.fromFirestore(doc)).toList();
      loaded = true;
    } catch (e) {
      debugPrint('BookCache load error: $e');
    } finally {
      loading = false;
    }
  }
}

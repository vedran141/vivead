import 'package:flutter/material.dart';

enum ReadingStatus { none, wantToRead, reading, read }

extension ReadingStatusX on ReadingStatus {
  String get firestoreValue {
    switch (this) {
      case ReadingStatus.wantToRead:
        return 'want_to_read';
      case ReadingStatus.reading:
        return 'reading';
      case ReadingStatus.read:
        return 'read';
      case ReadingStatus.none:
        return 'none';
    }
  }

  static ReadingStatus fromString(String? s) {
    switch (s) {
      case 'want_to_read':
        return ReadingStatus.wantToRead;
      case 'reading':
        return ReadingStatus.reading;
      case 'read':
        return ReadingStatus.read;
      default:
        return ReadingStatus.none;
    }
  }

  String get label {
    switch (this) {
      case ReadingStatus.none:
        return 'Add to Library';
      case ReadingStatus.wantToRead:
        return 'Want to Read';
      case ReadingStatus.reading:
        return 'Reading';
      case ReadingStatus.read:
        return 'Read';
    }
  }

  IconData get icon {
    switch (this) {
      case ReadingStatus.none:
        return Icons.add;
      case ReadingStatus.wantToRead:
        return Icons.bookmark_outline;
      case ReadingStatus.reading:
        return Icons.menu_book_outlined;
      case ReadingStatus.read:
        return Icons.check_circle_outline;
    }
  }
}

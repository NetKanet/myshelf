import 'package:flutter_riverpod/legacy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/providers.dart';
import '../../models/book.dart';
import '../../models/user_book.dart';
import '../../services/google_books_service.dart';
import '../../services/supabase_service.dart';

/// Normalize a scanned/typed ISBN: keep digits (and a trailing X for ISBN-10).
String normalizeIsbn(String raw) {
  final cleaned = raw.toUpperCase().replaceAll(RegExp(r'[^0-9X]'), '');
  return cleaned;
}

sealed class ScanState {
  const ScanState();
}

class ScanIdle extends ScanState {
  const ScanIdle();
}

class ScanLoading extends ScanState {
  final String isbn;
  const ScanLoading(this.isbn);
}

/// Book already on the user's shelf → caller should open it.
class ScanDuplicate extends ScanState {
  final String userBookId;
  const ScanDuplicate(this.userBookId);
}

/// Book added → caller should open its detail.
class ScanSuccess extends ScanState {
  final String userBookId;
  const ScanSuccess(this.userBookId);
}

/// Not found anywhere → caller should offer manual entry.
class ScanNotFound extends ScanState {
  final String isbn;
  const ScanNotFound(this.isbn);
}

class ScanError extends ScanState {
  final String message;
  const ScanError(this.message);
}

class ScanNotifier extends StateNotifier<ScanState> {
  final SupabaseService _supabase;
  final GoogleBooksService _googleBooks;
  final SupabaseClient _client;

  ScanNotifier(this._supabase, this._googleBooks, this._client)
      : super(const ScanIdle());

  String? get _userId => _client.auth.currentUser?.id;

  /// Cache-first ISBN flow: cache → shelf-duplicate → Google Books → manual.
  Future<void> onIsbnDetected(String rawIsbn) async {
    if (state is ScanLoading) return;
    final isbn = normalizeIsbn(rawIsbn);
    if (isbn.isEmpty) return;

    final userId = _userId;
    if (userId == null) {
      state = const ScanError('Not signed in');
      return;
    }
    state = ScanLoading(isbn);

    try {
      // 1. Cache-first: our own catalog.
      Book? book = await _supabase.getBookByIsbn(isbn);

      // 2. Already on the shelf? Open it, don't duplicate.
      if (book != null) {
        final existing = await _supabase.getUserBookByBookId(userId, book.id);
        if (existing != null) {
          state = ScanDuplicate(existing.id);
          return;
        }
      }

      // 3. Cache miss → Google Books; not found → manual fallback.
      if (book == null) {
        try {
          final partial = await _googleBooks.lookupByIsbn(isbn);
          book = await _supabase.insertBook(partial.toJson()..remove('id'));
        } on GoogleBooksException {
          state = ScanNotFound(isbn);
          return;
        }
      }

      // 4. Add to shelf as Want to Read.
      final userBook = await _supabase.insertUserBook(
        userId: userId,
        bookId: book.id,
        status: ReadingStatus.wantToRead.value,
      );
      state = ScanSuccess(userBook.id);
    } catch (e) {
      state = ScanError('Something went wrong: $e');
    }
  }

  /// Manual entry when the ISBN isn't found anywhere.
  Future<void> addManual({
    required String title,
    String? author,
    String? isbn,
  }) async {
    final userId = _userId;
    if (userId == null) {
      state = const ScanError('Not signed in');
      return;
    }
    state = const ScanLoading('manual');
    try {
      // Reuse an existing catalog row if one matches (avoid duplicates).
      Book? book = (isbn != null && isbn.isNotEmpty)
          ? await _supabase.getBookByIsbn(isbn)
          : await _supabase.getBookByTitleAuthor(title, author);

      if (book != null) {
        final existing = await _supabase.getUserBookByBookId(userId, book.id);
        if (existing != null) {
          state = ScanDuplicate(existing.id);
          return;
        }
      } else {
        book = await _supabase.insertBook({
          'title': title,
          if (author != null && author.isNotEmpty) 'author': author,
          if (isbn != null && isbn.isNotEmpty) 'isbn': isbn,
          'source': 'manual',
        });
      }

      final userBook = await _supabase.insertUserBook(
        userId: userId,
        bookId: book.id,
        status: ReadingStatus.wantToRead.value,
      );
      state = ScanSuccess(userBook.id);
    } catch (e) {
      state = ScanError('Failed to save: $e');
    }
  }

  void reset() => state = const ScanIdle();
}

final scanProvider = StateNotifierProvider<ScanNotifier, ScanState>(
  (ref) => ScanNotifier(
    ref.watch(supabaseServiceProvider),
    ref.watch(googleBooksServiceProvider),
    ref.watch(supabaseClientProvider),
  ),
);

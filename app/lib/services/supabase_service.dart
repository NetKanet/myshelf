import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/book.dart';
import '../models/user_book.dart';

/// All Supabase reads/writes for books and the user's shelf.
class SupabaseService {
  final SupabaseClient _client;
  SupabaseService(this._client);

  // ── books (shared catalog) ──────────────────────────────────────────────

  Future<Book?> getBookByIsbn(String isbn) async {
    final data =
        await _client.from('books').select().eq('isbn', isbn).maybeSingle();
    return data == null ? null : Book.fromJson(data);
  }

  Future<Book?> getBookByTitleAuthor(String title, String? author) async {
    var query = _client.from('books').select().eq('title', title);
    if (author != null && author.isNotEmpty) {
      query = query.eq('author', author);
    }
    final data = await query.limit(1).maybeSingle();
    return data == null ? null : Book.fromJson(data);
  }

  Future<Book> insertBook(Map<String, dynamic> data) async {
    final result = await _client.from('books').insert(data).select().single();
    return Book.fromJson(result);
  }

  // ── user_books (per-user shelf) ─────────────────────────────────────────

  Stream<List<UserBook>> watchUserBooks(String userId) {
    return _client
        .from('user_books')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .map((rows) => rows.map(UserBook.fromJson).toList());
  }

  /// All of the user's shelf entries with their book joined.
  Future<List<UserBook>> getUserBooks(String userId) async {
    final rows = await _client
        .from('user_books')
        .select('*, books(*)')
        .eq('user_id', userId);
    return (rows as List).map((r) => UserBook.fromJson(r)).toList();
  }

  Future<UserBook?> getUserBookById(String userBookId) async {
    final data = await _client
        .from('user_books')
        .select('*, books(*)')
        .eq('id', userBookId)
        .maybeSingle();
    return data == null ? null : UserBook.fromJson(data);
  }

  Future<UserBook?> getUserBookByBookId(String userId, String bookId) async {
    final data = await _client
        .from('user_books')
        .select('*, books(*)')
        .eq('user_id', userId)
        .eq('book_id', bookId)
        .maybeSingle();
    return data == null ? null : UserBook.fromJson(data);
  }

  Future<UserBook> insertUserBook({
    required String userId,
    required String bookId,
    required String status,
  }) async {
    final now = DateTime.now().toIso8601String();
    final result = await _client
        .from('user_books')
        .insert({
          'user_id': userId,
          'book_id': bookId,
          'status': status,
          'updated_at': now,
        })
        .select('*, books(*)')
        .single();
    return UserBook.fromJson(result);
  }

  Future<UserBook> updateUserBook({
    required String userBookId,
    required String status,
    String? dateStarted,
    bool clearDateStarted = false,
    String? dateFinished,
    bool clearDateFinished = false,
    double? rating,
    bool clearRating = false,
    String? review,
    bool clearReview = false,
  }) async {
    final updates = <String, dynamic>{
      'status': status,
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (clearDateStarted) {
      updates['date_started'] = null;
    } else if (dateStarted != null) {
      updates['date_started'] = dateStarted;
    }
    if (clearDateFinished) {
      updates['date_finished'] = null;
    } else if (dateFinished != null) {
      updates['date_finished'] = dateFinished;
    }
    if (clearRating) {
      updates['rating'] = null;
    } else if (rating != null) {
      updates['rating'] = rating;
    }
    if (clearReview) {
      updates['review'] = null;
    } else if (review != null) {
      updates['review'] = review;
    }

    final result = await _client
        .from('user_books')
        .update(updates)
        .eq('id', userBookId)
        .select('*, books(*)')
        .single();
    return UserBook.fromJson(result);
  }

  Future<void> deleteUserBook(String userBookId) async {
    await _client.from('user_books').delete().eq('id', userBookId);
  }
}

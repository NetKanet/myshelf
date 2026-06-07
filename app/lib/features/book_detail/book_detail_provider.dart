import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../core/providers.dart';
import '../../models/user_book.dart';
import '../../services/supabase_service.dart';

final bookDetailProvider = StateNotifierProvider.family<BookDetailNotifier,
    AsyncValue<UserBook?>, String>(
  (ref, userBookId) =>
      BookDetailNotifier(ref.watch(supabaseServiceProvider), userBookId),
);

class BookDetailNotifier extends StateNotifier<AsyncValue<UserBook?>> {
  final SupabaseService _service;
  final String _id;

  BookDetailNotifier(this._service, this._id)
      : super(const AsyncValue.loading()) {
    _load();
  }

  Future<void> _load() async {
    try {
      state = AsyncValue.data(await _service.getUserBookById(_id));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Saves status, dates, rating and review together. A status change never
  /// clears rating/review — they are retained (only an explicit null clears).
  Future<void> saveAll({
    required ReadingStatus status,
    DateTime? dateStarted,
    DateTime? dateFinished,
    double? rating,
    String? review,
  }) async {
    final updated = await _service.updateUserBook(
      userBookId: _id,
      status: status.value,
      dateStarted: dateStarted?.toIso8601String().split('T')[0],
      clearDateStarted: dateStarted == null,
      dateFinished: dateFinished?.toIso8601String().split('T')[0],
      clearDateFinished: dateFinished == null,
      rating: rating,
      clearRating: rating == null,
      review: (review != null && review.isNotEmpty) ? review : null,
      clearReview: review == null || review.isEmpty,
    );
    state = AsyncValue.data(updated);
  }

  Future<void> deleteFromShelf() async {
    await _service.deleteUserBook(_id);
    state = const AsyncValue.data(null);
  }
}

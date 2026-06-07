import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../core/providers.dart';
import '../../models/user_book.dart';
import '../auth/auth_provider.dart';

/// The filter chips shown above the shelf.
enum ShelfFilter {
  all('All'),
  reading('Reading'),
  finished('Finished'),
  wantToRead('Want to Read'),
  rated('Rated'),
  reviewed('Reviewed');

  const ShelfFilter(this.label);
  final String label;
}

/// Currently selected chip (defaults to All).
final shelfFilterProvider =
    StateProvider<ShelfFilter>((_) => ShelfFilter.all);

/// All of the signed-in user's shelf entries (book joined). Re-fetched on
/// invalidate after add/edit/delete.
final shelfBooksProvider = FutureProvider<List<UserBook>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  final books = await ref.watch(supabaseServiceProvider).getUserBooks(user.id);
  return sortShelf(books);
});

/// The shelf after applying the active filter chip.
final filteredShelfProvider = Provider<AsyncValue<List<UserBook>>>((ref) {
  final filter = ref.watch(shelfFilterProvider);
  return ref.watch(shelfBooksProvider).whenData(
        (books) => filterShelf(books, filter),
      );
});

// ── Pure helpers (unit-testable, no Supabase) ───────────────────────────────

/// Filters [books] by [filter]. Rated/Reviewed are derived (rating/review set).
List<UserBook> filterShelf(List<UserBook> books, ShelfFilter filter) {
  switch (filter) {
    case ShelfFilter.all:
      return books;
    case ShelfFilter.reading:
      return books.where((b) => b.status == ReadingStatus.reading).toList();
    case ShelfFilter.finished:
      return books.where((b) => b.status == ReadingStatus.finished).toList();
    case ShelfFilter.wantToRead:
      return books.where((b) => b.status == ReadingStatus.wantToRead).toList();
    case ShelfFilter.rated:
      return books.where((b) => b.rating != null).toList();
    case ShelfFilter.reviewed:
      return books
          .where((b) => b.review != null && b.review!.isNotEmpty)
          .toList();
  }
}

/// Finished books sort by finish date desc; everything else by created_at desc.
/// Returns a single list with finished first (by finish date), then the rest.
List<UserBook> sortShelf(List<UserBook> books) {
  final finished = books
      .where((b) => b.status == ReadingStatus.finished)
      .toList()
    ..sort((a, b) => (b.dateFinished ?? b.createdAt)
        .compareTo(a.dateFinished ?? a.createdAt));
  final others = books
      .where((b) => b.status != ReadingStatus.finished)
      .toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  return [...finished, ...others];
}

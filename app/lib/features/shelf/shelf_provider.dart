import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../core/providers.dart';
import '../../models/user_book.dart';
import '../auth/auth_provider.dart';

/// Shelf filter options.
enum ShelfFilter {
  all('All'),
  reading('Reading'),
  finished('Finished'),
  wantToRead('Want to Read');

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
  }
}

/// A section header in the grouped shelf list (title + how many books in it).
class ShelfSection {
  final String title;
  final int count;
  const ShelfSection(this.title, this.count);
}

String _sectionKey(UserBook b) => switch (b.status) {
      ReadingStatus.finished => '${(b.dateFinished ?? b.createdAt).year}',
      ReadingStatus.reading => 'Reading',
      ReadingStatus.wantToRead => 'Want to Read',
    };

/// Turns a sorted book list into a flat list of [ShelfSection] headers and
/// [UserBook]s, grouped by finish year (finished books) then by status.
/// Example: "2026", book, book, "2025", book, "Reading", book, "Want to Read".
List<Object> groupShelf(List<UserBook> sortedBooks) {
  // Count per section first (sections are contiguous in the sorted list).
  final counts = <String, int>{};
  for (final b in sortedBooks) {
    final k = _sectionKey(b);
    counts[k] = (counts[k] ?? 0) + 1;
  }
  final out = <Object>[];
  String? current;
  for (final b in sortedBooks) {
    final key = _sectionKey(b);
    if (key != current) {
      out.add(ShelfSection(key, counts[key]!));
      current = key;
    }
    out.add(b);
  }
  return out;
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

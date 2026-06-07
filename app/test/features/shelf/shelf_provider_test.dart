import 'package:flutter_test/flutter_test.dart';
import 'package:myshelf/features/shelf/shelf_provider.dart';
import 'package:myshelf/models/book.dart';
import 'package:myshelf/models/user_book.dart';

UserBook ub({
  required String id,
  required ReadingStatus status,
  DateTime? dateFinished,
  DateTime? createdAt,
  double? rating,
  String? review,
}) {
  return UserBook(
    id: id,
    userId: 'u1',
    bookId: 'b_$id',
    status: status,
    dateFinished: dateFinished,
    rating: rating,
    review: review,
    createdAt: createdAt ?? DateTime(2026, 1, 1),
    updatedAt: createdAt ?? DateTime(2026, 1, 1),
    book: Book(id: 'b_$id', title: 'Book $id'),
  );
}

void main() {
  final reading = ub(id: 'r', status: ReadingStatus.reading);
  final want = ub(id: 'w', status: ReadingStatus.wantToRead);
  final finishedRated = ub(
    id: 'f1',
    status: ReadingStatus.finished,
    dateFinished: DateTime(2026, 6, 1),
    rating: 4.5,
    review: 'Great',
  );
  final finishedOld = ub(
    id: 'f2',
    status: ReadingStatus.finished,
    dateFinished: DateTime(2026, 1, 15),
  );
  final all = [reading, want, finishedRated, finishedOld];

  group('filterShelf', () {
    test('All returns everything', () {
      expect(filterShelf(all, ShelfFilter.all).length, 4);
    });

    test('Reading / Finished / Want filter by status', () {
      expect(filterShelf(all, ShelfFilter.reading), [reading]);
      expect(filterShelf(all, ShelfFilter.wantToRead), [want]);
      expect(
        filterShelf(all, ShelfFilter.finished).map((e) => e.id).toSet(),
        {'f1', 'f2'},
      );
    });

    test('empty when no books match', () {
      expect(filterShelf([reading], ShelfFilter.finished), isEmpty);
    });
  });

  group('groupShelf', () {
    test('groups finished by year, then status sections', () {
      final f2026 = ub(
          id: 'a',
          status: ReadingStatus.finished,
          dateFinished: DateTime(2026, 6, 1));
      final f2025 = ub(
          id: 'b',
          status: ReadingStatus.finished,
          dateFinished: DateTime(2025, 2, 1));
      final read = ub(id: 'c', status: ReadingStatus.reading);
      final items = groupShelf([f2026, f2025, read]);

      final headers =
          items.whereType<ShelfSection>().map((s) => s.title).toList();
      expect(headers, ['2026', '2025', 'Reading']);
      expect(items.length, 6); // 3 headers + 3 books
    });
  });

  group('sortShelf', () {
    test('finished first, by date_finished desc', () {
      final sorted = sortShelf(all);
      // f1 (Jun) before f2 (Jan) among finished, and finished come first.
      expect(sorted.first.id, 'f1');
      expect(sorted[1].id, 'f2');
    });

    test('non-finished sorted by created_at desc', () {
      final a = ub(
        id: 'a',
        status: ReadingStatus.reading,
        createdAt: DateTime(2026, 3, 1),
      );
      final b = ub(
        id: 'b',
        status: ReadingStatus.reading,
        createdAt: DateTime(2026, 5, 1),
      );
      final sorted = sortShelf([a, b]);
      expect(sorted.map((e) => e.id).toList(), ['b', 'a']);
    });
  });
}

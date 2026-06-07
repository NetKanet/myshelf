import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:myshelf/features/book_detail/book_detail_provider.dart';
import 'package:myshelf/models/book.dart';
import 'package:myshelf/models/user_book.dart';
import 'package:myshelf/services/supabase_service.dart';

class MockSupabaseService extends Mock implements SupabaseService {}

const id = 'ub1';

UserBook base({
  ReadingStatus status = ReadingStatus.reading,
  double? rating,
  String? review,
}) =>
    UserBook(
      id: id,
      userId: 'u1',
      bookId: 'b1',
      status: status,
      rating: rating,
      review: review,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
      book: const Book(id: 'b1', title: 'T'),
    );

void main() {
  late MockSupabaseService service;

  setUp(() {
    service = MockSupabaseService();
    when(() => service.getUserBookById(id))
        .thenAnswer((_) async => base());
  });

  Future<(BookDetailNotifier, List<AsyncValue<UserBook?>>)> make() async {
    final n = BookDetailNotifier(service, id);
    final states = <AsyncValue<UserBook?>>[];
    n.addListener(states.add);
    await Future<void>.delayed(Duration.zero); // let _load finish
    return (n, states);
  }

  test('saveAll(finished) persists rating + review (not cleared)', () async {
    final expected = base(
      status: ReadingStatus.finished,
      rating: 4.5,
      review: 'Great',
    );
    when(() => service.updateUserBook(
          userBookId: id,
          status: 'finished',
          dateStarted: '2026-05-01',
          clearDateStarted: false,
          dateFinished: '2026-06-01',
          clearDateFinished: false,
          rating: 4.5,
          clearRating: false,
          review: 'Great',
          clearReview: false,
        )).thenAnswer((_) async => expected);

    final (n, _) = await make();
    await n.saveAll(
      status: ReadingStatus.finished,
      dateStarted: DateTime(2026, 5, 1),
      dateFinished: DateTime(2026, 6, 1),
      rating: 4.5,
      review: 'Great',
    );

    verify(() => service.updateUserBook(
          userBookId: id,
          status: 'finished',
          dateStarted: '2026-05-01',
          clearDateStarted: false,
          dateFinished: '2026-06-01',
          clearDateFinished: false,
          rating: 4.5,
          clearRating: false,
          review: 'Great',
          clearReview: false,
        )).called(1);
  });

  test('saveAll(wantToRead) clears dates but keeps rating/review when passed',
      () async {
    when(() => service.updateUserBook(
          userBookId: id,
          status: 'want_to_read',
          dateStarted: null,
          clearDateStarted: true,
          dateFinished: null,
          clearDateFinished: true,
          rating: 4.0,
          clearRating: false,
          review: null,
          clearReview: true,
        )).thenAnswer((_) async => base(status: ReadingStatus.wantToRead));

    final (n, _) = await make();
    await n.saveAll(status: ReadingStatus.wantToRead, rating: 4.0);

    verify(() => service.updateUserBook(
          userBookId: id,
          status: 'want_to_read',
          dateStarted: null,
          clearDateStarted: true,
          dateFinished: null,
          clearDateFinished: true,
          rating: 4.0,
          clearRating: false,
          review: null,
          clearReview: true,
        )).called(1);
  });

  test('deleteFromShelf removes and nulls state', () async {
    when(() => service.deleteUserBook(id)).thenAnswer((_) async {});

    final (n, states) = await make();
    await n.deleteFromShelf();

    verify(() => service.deleteUserBook(id)).called(1);
    expect(states.last, isA<AsyncData<UserBook?>>());
    expect((states.last as AsyncData<UserBook?>).value, isNull);
  });
}

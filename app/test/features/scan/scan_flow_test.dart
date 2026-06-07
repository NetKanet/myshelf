import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:myshelf/features/scan/scan_provider.dart';
import 'package:myshelf/models/book.dart';
import 'package:myshelf/models/user_book.dart';
import 'package:myshelf/services/google_books_service.dart';
import 'package:myshelf/services/supabase_service.dart';

class MockSupabaseService extends Mock implements SupabaseService {}

class MockGoogleBooksService extends Mock implements GoogleBooksService {}

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockGoTrueClient extends Mock implements GoTrueClient {}

class MockUser extends Mock implements User {}

const isbn = '9781234567890';
const userId = 'user-1';
const bookId = 'book-1';
const userBookId = 'ub-1';

Book book() => const Book(id: bookId, isbn: isbn, title: 'Test Book');

UserBook userBook() => UserBook(
      id: userBookId,
      userId: userId,
      bookId: bookId,
      status: ReadingStatus.wantToRead,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
      book: book(),
    );

void main() {
  setUpAll(() => registerFallbackValue(<String, dynamic>{}));

  late MockSupabaseService supabase;
  late MockGoogleBooksService google;
  late MockSupabaseClient client;
  late MockGoTrueClient auth;
  late MockUser user;

  setUp(() {
    supabase = MockSupabaseService();
    google = MockGoogleBooksService();
    client = MockSupabaseClient();
    auth = MockGoTrueClient();
    user = MockUser();
    when(() => client.auth).thenReturn(auth);
    when(() => auth.currentUser).thenReturn(user);
    when(() => user.id).thenReturn(userId);
    when(() => supabase.insertUserBook(
          userId: userId,
          bookId: bookId,
          status: 'want_to_read',
        )).thenAnswer((_) async => userBook());
  });

  /// Runs an action against a fresh notifier and returns its final state.
  Future<ScanState> run(Future<void> Function(ScanNotifier) action) async {
    final n = ScanNotifier(supabase, google, client);
    late ScanState last;
    n.addListener((s) => last = s); // fires immediately with current state
    await action(n);
    return last;
  }

  test('cache hit, not on shelf → success without external lookup', () async {
    when(() => supabase.getBookByIsbn(isbn)).thenAnswer((_) async => book());
    when(() => supabase.getUserBookByBookId(userId, bookId))
        .thenAnswer((_) async => null);

    final state = await run((n) => n.onIsbnDetected(isbn));

    expect(state, isA<ScanSuccess>());
    verifyNever(() => google.lookupByIsbn(any()));
  });

  test('cache hit, already on shelf → duplicate', () async {
    when(() => supabase.getBookByIsbn(isbn)).thenAnswer((_) async => book());
    when(() => supabase.getUserBookByBookId(userId, bookId))
        .thenAnswer((_) async => userBook());

    final state = await run((n) => n.onIsbnDetected(isbn));

    expect(state, isA<ScanDuplicate>());
  });

  test('cache miss → Google found → inserts + success', () async {
    when(() => supabase.getBookByIsbn(isbn)).thenAnswer((_) async => null);
    when(() => google.lookupByIsbn(isbn)).thenAnswer((_) async => book());
    when(() => supabase.insertBook(any())).thenAnswer((_) async => book());

    final state = await run((n) => n.onIsbnDetected(isbn));

    expect(state, isA<ScanSuccess>());
    verify(() => supabase.insertBook(any())).called(1);
  });

  test('cache miss → Google not found → notFound', () async {
    when(() => supabase.getBookByIsbn(isbn)).thenAnswer((_) async => null);
    when(() => google.lookupByIsbn(isbn))
        .thenThrow(const GoogleBooksException('ISBN not found'));

    final state = await run((n) => n.onIsbnDetected(isbn));

    expect(state, isA<ScanNotFound>());
  });

  test('manual add → new catalog row → success', () async {
    when(() => supabase.getBookByTitleAuthor('Manual', 'Auth'))
        .thenAnswer((_) async => null);
    when(() => supabase.insertBook(any())).thenAnswer((_) async => book());

    final state = await run((n) => n.addManual(title: 'Manual', author: 'Auth'));

    expect(state, isA<ScanSuccess>());
    verify(() => supabase.insertBook(any())).called(1);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:myshelf/features/auth/auth_provider.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockGoTrueClient extends Mock implements GoTrueClient {}

void main() {
  setUpAll(() => registerFallbackValue(OAuthProvider.google));

  late MockSupabaseClient client;
  late MockGoTrueClient auth;

  setUp(() {
    client = MockSupabaseClient();
    auth = MockGoTrueClient();
    when(() => client.auth).thenReturn(auth);
  });

  test('cancelled sign-in (null token) leaves idle state, no auth call',
      () async {
    final controller =
        AuthController(client, idTokenFetcher: () async => null);
    Object? last;
    controller.addListener((s) => last = s);

    await controller.signInWithGoogle();

    expect(last, isA<AsyncData<void>>());
    verifyNever(() => auth.signInWithIdToken(
          provider: any(named: 'provider'),
          idToken: any(named: 'idToken'),
        ));
  });

  test('fetcher error surfaces as error state', () async {
    final controller = AuthController(
      client,
      idTokenFetcher: () async => throw const AuthException('boom'),
    );
    Object? last;
    controller.addListener((s) => last = s);

    await controller.signInWithGoogle();

    expect(last, isA<AsyncError<void>>());
  });
}

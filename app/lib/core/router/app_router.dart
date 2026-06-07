import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers.dart';
import '../../features/auth/auth_screen.dart';
import '../../features/shelf/shelf_screen.dart';
import '../../features/scan/scan_screen.dart';
import '../../features/book_detail/book_detail_screen.dart';

/// App router with an auth redirect: signed-out → /login, signed-in → /shelf.
final routerProvider = Provider<GoRouter>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final refresh = GoRouterRefreshStream(client.auth.onAuthStateChange);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: '/shelf',
    refreshListenable: refresh,
    redirect: (context, state) {
      final loggedIn = client.auth.currentUser != null;
      final loggingIn = state.matchedLocation == '/login';
      if (!loggedIn) return loggingIn ? null : '/login';
      if (loggingIn) return '/shelf';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, _) => const AuthScreen()),
      GoRoute(path: '/shelf', builder: (_, _) => const ShelfScreen()),
      GoRoute(path: '/scan', builder: (_, _) => const ScanScreen()),
      GoRoute(
        path: '/book/:id',
        builder: (_, state) =>
            BookDetailScreen(userBookId: state.pathParameters['id']!),
      ),
    ],
  );
});

/// Bridges a [Stream] to a [Listenable] so GoRouter re-evaluates redirects.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _sub = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _sub;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

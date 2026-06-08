import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers.dart';
import '../../features/auth/auth_screen.dart';
import '../../features/home/home_shell.dart';
import '../../features/scan/scan_screen.dart';
import '../../features/scan/manual_entry_screen.dart';
import '../../features/book_detail/book_detail_screen.dart';

/// App router with an auth redirect: signed-out → /login, signed-in → /home.
final routerProvider = Provider<GoRouter>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final refresh = GoRouterRefreshStream(client.auth.onAuthStateChange);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: '/home',
    refreshListenable: refresh,
    redirect: (context, state) {
      final loggedIn = client.auth.currentUser != null;
      final loggingIn = state.matchedLocation == '/login';
      if (!loggedIn) return loggingIn ? null : '/login';
      if (loggingIn) return '/home';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, _) => const AuthScreen()),
      GoRoute(path: '/home', builder: (_, _) => const HomeShell()),
      GoRoute(path: '/scan', builder: (_, _) => const ScanScreen()),
      GoRoute(
          path: '/add-manual',
          builder: (_, _) => const ManualEntryScreen()),
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

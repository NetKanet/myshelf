import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/supabase_service.dart';
import '../services/google_books_service.dart';

/// App theme mode (light/dark). In-memory for now.
final themeModeProvider = StateProvider<ThemeMode>((_) => ThemeMode.light);

/// Shared, app-wide providers.

final supabaseClientProvider = Provider<SupabaseClient>(
  (_) => Supabase.instance.client,
);

final supabaseServiceProvider = Provider<SupabaseService>(
  (ref) => SupabaseService(ref.watch(supabaseClientProvider)),
);

final googleBooksServiceProvider = Provider<GoogleBooksService>(
  (_) => GoogleBooksService(),
);

/// Emits the current auth state; the router and UI react to this.
final authStateProvider = StreamProvider<AuthState>(
  (ref) => ref.watch(supabaseClientProvider).auth.onAuthStateChange,
);

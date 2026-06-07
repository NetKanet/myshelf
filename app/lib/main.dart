import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/config/supabase_config.dart';
import 'core/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: SupabaseConfig.url,
    publishableKey: SupabaseConfig.publishableKey,
  );
  runApp(const ProviderScope(child: MyShelfApp()));
}

/// Convenience accessor for the Supabase client.
final supabase = Supabase.instance.client;

class MyShelfApp extends StatelessWidget {
  const MyShelfApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Router is wired in T012 (core/router/app_router.dart).
    return MaterialApp(
      title: 'My Shelf',
      theme: AppTheme.light,
      debugShowCheckedModeBanner: false,
      home: const Scaffold(
        body: Center(child: Text('My Shelf — setup complete')),
      ),
    );
  }
}

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import 'auth_provider.dart';
import 'widgets/google_logo.dart';

class AuthScreen extends ConsumerWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(authControllerProvider);
    final isLoading = state.isLoading;
    final error = state.hasError ? state.error.toString() : null;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.auto_stories_rounded,
                  size: 88, color: AppColors.lavender),
              const SizedBox(height: 20),
              Text('My Shelf',
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontSize: 34)),
              const SizedBox(height: 8),
              Text(
                'Your personal bookshelf',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.navy.withValues(alpha: 0.6),
                    ),
              ),
              const SizedBox(height: 48),
              if (error != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.coral.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    error,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.coral),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              ElevatedButton.icon(
                onPressed: isLoading
                    ? null
                    : () => ref
                        .read(authControllerProvider.notifier)
                        .signInWithGoogle(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.navy,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: const BorderSide(color: AppColors.lavender),
                  ),
                ),
                icon: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const GoogleLogo(size: 20),
                label: Text(isLoading ? 'Signing in…' : 'Sign in with Google'),
              ),
              if (kDebugMode) ...[
                const SizedBox(height: 24),
                _DebugLogin(enabled: !isLoading),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Debug-only email/password login (compiled out of release builds).
class _DebugLogin extends ConsumerStatefulWidget {
  final bool enabled;
  const _DebugLogin({required this.enabled});

  @override
  ConsumerState<_DebugLogin> createState() => _DebugLoginState();
}

class _DebugLoginState extends ConsumerState<_DebugLogin> {
  final _email = TextEditingController(text: 'netto_kanet@hotmail.com');
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      title: const Text('Debug login (dev only)',
          style: TextStyle(fontSize: 13, color: AppColors.lavender)),
      tilePadding: EdgeInsets.zero,
      childrenPadding: const EdgeInsets.only(bottom: 8),
      children: [
        TextField(
          controller: _email,
          decoration: const InputDecoration(
              labelText: 'Email', isDense: true),
          keyboardType: TextInputType.emailAddress,
          autocorrect: false,
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _password,
          decoration: const InputDecoration(
              labelText: 'Password', isDense: true),
          obscureText: true,
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: widget.enabled
                ? () => ref
                    .read(authControllerProvider.notifier)
                    .signInWithPassword(
                      _email.text.trim(),
                      _password.text,
                    )
                : null,
            child: const Text('Debug sign in'),
          ),
        ),
      ],
    );
  }
}

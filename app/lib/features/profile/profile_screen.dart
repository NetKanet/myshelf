import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../auth/auth_provider.dart';
import 'profile_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final stats = ref.watch(profileStatsProvider);
    final name = user?.userMetadata?['name'] as String? ??
        user?.email ??
        'Reader';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Sign out',
            onPressed: () =>
                ref.read(authControllerProvider.notifier).signOut(),
          ),
        ],
      ),
      body: stats.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (s) => ListView(
          padding: const EdgeInsets.all(24),
          children: [
            _Header(name: name, email: user?.email),
            const SizedBox(height: 24),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.1,
              children: [
                _StatCard(label: 'Reading', value: '${s.reading}'),
                _StatCard(label: 'Finished', value: '${s.finished}'),
                _StatCard(label: 'Want to Read', value: '${s.wantToRead}'),
                _StatCard(label: 'Rated', value: '${s.rated}'),
                _StatCard(label: 'Reviewed', value: '${s.reviewed}'),
                _StatCard(
                  label: 'Avg rating',
                  value: s.avgRating == null
                      ? '—'
                      : s.avgRating!.toStringAsFixed(1),
                ),
              ],
            ),
            const SizedBox(height: 28),
            Text('Recent reviews',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontSize: 16)),
            const SizedBox(height: 12),
            if (s.recentReviews.isEmpty)
              Text('No reviews yet.',
                  style: TextStyle(
                      color: AppColors.navy.withValues(alpha: 0.5)))
            else
              ...s.recentReviews.map((ub) => Card(
                    color: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      onTap: () => context.push('/book/${ub.id}'),
                      title: Text(ub.book?.title ?? 'Unknown',
                          style:
                              const TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: Text(ub.review ?? '',
                          maxLines: 2, overflow: TextOverflow.ellipsis),
                      trailing: ub.rating != null
                          ? Text('${ub.rating}★',
                              style:
                                  const TextStyle(color: AppColors.navy))
                          : null,
                    ),
                  )),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String name;
  final String? email;
  const _Header({required this.name, this.email});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const CircleAvatar(
          radius: 28,
          backgroundColor: AppColors.lavender,
          child: Icon(Icons.person, color: Colors.white, size: 32),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name,
                  style: Theme.of(context).textTheme.titleLarge,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              if (email != null && email != name)
                Text(email!,
                    style: TextStyle(
                        color: AppColors.navy.withValues(alpha: 0.5)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  const _StatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(value,
              style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.navy)),
          const SizedBox(height: 4),
          Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 11,
                  color: AppColors.navy.withValues(alpha: 0.5))),
        ],
      ),
    );
  }
}

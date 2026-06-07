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
    final statsAsync = ref.watch(profileStatsProvider);
    final name =
        user?.userMetadata?['name'] as String? ?? user?.email ?? 'Reader';

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
      body: statsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (s) => ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _Header(name: name, email: user?.email),
            const SizedBox(height: 20),
            _StatusBreakdown(s: s),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _MiniMetric(
                    label: 'Avg rating',
                    child: s.avgRating == null
                        ? const Text('—',
                            style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: AppColors.navy))
                        : _StarsValue(value: s.avgRating!),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MiniMetric(
                    label: 'Reviews',
                    child: Text('${s.reviewed}',
                        style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: AppColors.navy)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (s.finishedByYear.isNotEmpty) ...[
              _SectionTitle('Finished per year'),
              const SizedBox(height: 12),
              _YearChart(data: s.finishedByYear),
              const SizedBox(height: 24),
            ],
            _SectionTitle('Recent reviews'),
            const SizedBox(height: 12),
            if (s.recentReviews.isEmpty)
              Text('No reviews yet.',
                  style:
                      TextStyle(color: AppColors.navy.withValues(alpha: 0.5)))
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
                              style: const TextStyle(color: AppColors.navy))
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

/// Horizontal proportional bars for Reading / Finished / Want to Read.
class _StatusBreakdown extends StatelessWidget {
  final ProfileStats s;
  const _StatusBreakdown({required this.s});

  @override
  Widget build(BuildContext context) {
    final max = [s.reading, s.finished, s.wantToRead, 1]
        .reduce((a, b) => a > b ? a : b);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _Bar(
              label: 'Reading',
              value: s.reading,
              max: max,
              color: AppColors.lavender),
          const SizedBox(height: 12),
          _Bar(
              label: 'Finished',
              value: s.finished,
              max: max,
              color: AppColors.mint),
          const SizedBox(height: 12),
          _Bar(
              label: 'Want to Read',
              value: s.wantToRead,
              max: max,
              color: AppColors.coral),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  final String label;
  final int value;
  final int max;
  final Color color;
  const _Bar(
      {required this.label,
      required this.value,
      required this.max,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 92,
          child: Text(label,
              style: TextStyle(
                  fontSize: 12,
                  color: AppColors.navy.withValues(alpha: 0.7))),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Stack(
              children: [
                Container(
                    height: 16,
                    color: AppColors.lavender.withValues(alpha: 0.15)),
                FractionallySizedBox(
                  widthFactor: max == 0 ? 0 : value / max,
                  child: Container(height: 16, color: color),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 22,
          child: Text('$value',
              textAlign: TextAlign.right,
              style: const TextStyle(
                  fontWeight: FontWeight.w800, color: AppColors.navy)),
        ),
      ],
    );
  }
}

class _MiniMetric extends StatelessWidget {
  final String label;
  final Widget child;
  const _MiniMetric({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          child,
          const SizedBox(height: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  color: AppColors.navy.withValues(alpha: 0.5))),
        ],
      ),
    );
  }
}

class _StarsValue extends StatelessWidget {
  final double value;
  const _StarsValue({required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ...List.generate(5, (i) {
          final pos = i + 1;
          final icon = value >= pos
              ? Icons.star_rounded
              : value >= pos - 0.5
                  ? Icons.star_half_rounded
                  : Icons.star_outline_rounded;
          return Icon(icon, size: 16, color: AppColors.yellow);
        }),
        const SizedBox(width: 6),
        Text(value.toStringAsFixed(1),
            style: const TextStyle(
                fontWeight: FontWeight.w800, color: AppColors.navy)),
      ],
    );
  }
}

/// Simple horizontal bar chart of finished books per year.
class _YearChart extends StatelessWidget {
  final List<MapEntry<int, int>> data;
  const _YearChart({required this.data});

  @override
  Widget build(BuildContext context) {
    final max = data.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          for (final e in data) ...[
            _Bar(
                label: '${e.key}',
                value: e.value,
                max: max,
                color: AppColors.yellow),
            if (e != data.last) const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style:
            Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 16));
  }
}

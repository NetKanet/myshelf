import 'package:fl_chart/fl_chart.dart';
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
            if (s.finished > 0) ...[
              _SectionTitle('Finished in ${s.monthlyYear}'),
              const SizedBox(height: 12),
              _ChartCard(
                child: SizedBox(
                  height: 160,
                  child: _MonthlyChart(months: s.finishedByMonth),
                ),
              ),
              const SizedBox(height: 20),
              if (s.finishedByYear.length > 1) ...[
                _SectionTitle('Finished per year'),
                const SizedBox(height: 12),
                _ChartCard(
                  child: SizedBox(
                    height: 160,
                    child: _YearlyChart(data: s.finishedByYear),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ],
            const SizedBox(height: 4),
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

class _ChartCard extends StatelessWidget {
  final Widget child;
  const _ChartCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }
}

const _monthLabels = [
  'J', 'F', 'M', 'A', 'M', 'J', 'J', 'A', 'S', 'O', 'N', 'D'
];

/// Vertical bar chart: finished books per month (Jan..Dec).
class _MonthlyChart extends StatelessWidget {
  final List<int> months; // length 12
  const _MonthlyChart({required this.months});

  @override
  Widget build(BuildContext context) {
    final maxV =
        months.fold<int>(1, (m, v) => v > m ? v : m).toDouble();
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxV + 1,
        borderData: FlBorderData(show: false),
        gridData: const FlGridData(show: false),
        barTouchData: BarTouchData(enabled: false),
        titlesData: FlTitlesData(
          leftTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (v, _) => Text(
                _monthLabels[v.toInt() % 12],
                style: TextStyle(
                    fontSize: 10,
                    color: AppColors.navy.withValues(alpha: 0.5)),
              ),
            ),
          ),
        ),
        barGroups: [
          for (var i = 0; i < 12; i++)
            BarChartGroupData(x: i, barRods: [
              BarChartRodData(
                toY: months[i].toDouble(),
                color: AppColors.mint,
                width: 12,
                borderRadius: BorderRadius.circular(4),
              ),
            ]),
        ],
      ),
    );
  }
}

/// Vertical bar chart: finished books per year.
class _YearlyChart extends StatelessWidget {
  final List<MapEntry<int, int>> data; // newest first
  const _YearlyChart({required this.data});

  @override
  Widget build(BuildContext context) {
    final ordered = data.reversed.toList(); // oldest → newest on x-axis
    final maxV =
        ordered.fold<int>(1, (m, e) => e.value > m ? e.value : m).toDouble();
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxV + 1,
        borderData: FlBorderData(show: false),
        gridData: const FlGridData(show: false),
        barTouchData: BarTouchData(enabled: false),
        titlesData: FlTitlesData(
          leftTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (v, _) {
                final i = v.toInt();
                if (i < 0 || i >= ordered.length) return const SizedBox();
                return Text('${ordered[i].key}',
                    style: TextStyle(
                        fontSize: 10,
                        color: AppColors.navy.withValues(alpha: 0.5)));
              },
            ),
          ),
        ),
        barGroups: [
          for (var i = 0; i < ordered.length; i++)
            BarChartGroupData(x: i, barRods: [
              BarChartRodData(
                toY: ordered[i].value.toDouble(),
                color: AppColors.yellow,
                width: 18,
                borderRadius: BorderRadius.circular(4),
              ),
            ]),
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

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/deco_background.dart';
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
    final avatarUrl = (user?.userMetadata?['avatar_url'] ??
        user?.userMetadata?['picture']) as String?;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () => _showSettings(context, ref),
          ),
        ],
      ),
      body: DecoBackground(
        child: statsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (s) {
            final thisYear = s.finishedByYear
                .where((e) => e.key == DateTime.now().year)
                .fold<int>(0, (a, e) => a + e.value);
            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _Header(name: name, email: user?.email, avatarUrl: avatarUrl),
                const SizedBox(height: 20),
                // Headline numbers (reading progress at a glance).
                Row(
                  children: [
                    Expanded(
                      child: _MiniMetric(
                        label: 'Books finished',
                        child: _BigNumber('${s.finished}'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _MiniMetric(
                        label: 'This year',
                        child: _BigNumber('$thisYear'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _MiniMetric(
                        label: 'Avg rating',
                        child: s.avgRating == null
                            ? _BigNumber('—')
                            : _BigNumber(s.avgRating!.toStringAsFixed(1)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _SectionTitle('Currently'),
                const SizedBox(height: 12),
                _StatusBreakdown(s: s),
                if (s.finished > 0) ...[
                  const SizedBox(height: 24),
                  _SectionTitle('Finished in ${s.monthlyYear}'),
                  const SizedBox(height: 12),
                  _ChartCard(
                    child: SizedBox(
                      height: 170,
                      child: _MonthlyChart(months: s.finishedByMonth),
                    ),
                  ),
                  if (s.finishedByYearMonth.length > 1) ...[
                    const SizedBox(height: 20),
                    _SectionTitle('By month, per year'),
                    const SizedBox(height: 12),
                    _ChartCard(
                      child: _YearMonthlyChart(data: s.finishedByYearMonth),
                    ),
                  ],
                ],
                const SizedBox(height: 24),
              ],
            );
          },
        ),
      ),
    );
  }

  void _showSettings(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        // Paint the panel inside the Consumer so flipping the toggle
        // recolours the sheet itself live (not just its contents).
        return Consumer(
          builder: (context, ref, _) {
            final mode = ref.watch(themeModeProvider);
            final isDark = mode == ThemeMode.dark;
            return Container(
              decoration: BoxDecoration(
                color: AppColors.surface(context),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 12),
                    Text(
                      'Settings',
                      style: Theme.of(
                        context,
                      ).textTheme.titleLarge?.copyWith(fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      secondary: Icon(
                        isDark
                            ? Icons.dark_mode_rounded
                            : Icons.light_mode_rounded,
                        color: AppColors.ink(context),
                      ),
                      title: const Text('Dark mode'),
                      value: isDark,
                      activeThumbColor: AppColors.yellow,
                      onChanged: (v) =>
                          ref.read(themeModeProvider.notifier).state = v
                          ? ThemeMode.dark
                          : ThemeMode.light,
                    ),
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          icon: const Icon(
                            Icons.logout_rounded,
                            color: AppColors.coral,
                          ),
                          label: const Text(
                            'Sign out',
                            style: TextStyle(color: AppColors.coral),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: const BorderSide(color: AppColors.coral),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                            ref.read(authControllerProvider.notifier).signOut();
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  final String name;
  final String? email;
  final String? avatarUrl;
  const _Header({required this.name, this.email, this.avatarUrl});

  @override
  Widget build(BuildContext context) {
    final hasAvatar = avatarUrl != null && avatarUrl!.isNotEmpty;
    return Row(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: AppColors.lavender,
          backgroundImage: hasAvatar ? NetworkImage(avatarUrl!) : null,
          child: hasAvatar
              ? null
              : const Icon(Icons.person, color: Colors.white, size: 32),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontSize: 18),
                maxLines: 2,
                softWrap: true,
                overflow: TextOverflow.ellipsis,
              ),
              if (email != null && email != name)
                Text(
                  email!,
                  style: TextStyle(
                    color: AppColors.ink(context).withValues(alpha: 0.5),
                  ),
                  maxLines: 2,
                  softWrap: true,
                  overflow: TextOverflow.ellipsis,
                ),
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
    final max = [
      s.reading,
      s.finished,
      s.wantToRead,
      1,
    ].reduce((a, b) => a > b ? a : b);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _Bar(
            label: 'Reading',
            value: s.reading,
            max: max,
            color: AppColors.lavender,
          ),
          const SizedBox(height: 12),
          _Bar(
            label: 'Finished',
            value: s.finished,
            max: max,
            color: AppColors.mint,
          ),
          const SizedBox(height: 12),
          _Bar(
            label: 'Want to Read',
            value: s.wantToRead,
            max: max,
            color: AppColors.coral,
          ),
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
  const _Bar({
    required this.label,
    required this.value,
    required this.max,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 92,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.ink(context).withValues(alpha: 0.7),
            ),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Stack(
              children: [
                Container(
                  height: 16,
                  color: AppColors.lavender.withValues(alpha: 0.15),
                ),
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
          child: Text(
            '$value',
            textAlign: TextAlign.right,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: AppColors.ink(context),
            ),
          ),
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
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          child,
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: AppColors.ink(context).withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _BigNumber extends StatelessWidget {
  final String value;
  const _BigNumber(this.value);

  @override
  Widget build(BuildContext context) {
    return Text(
      value,
      style: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w800,
        color: AppColors.ink(context),
      ),
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
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }
}

const _monthLabels = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

/// Left axis showing whole-number book counts.
AxisTitles _countAxis(BuildContext context, double maxV) => AxisTitles(
  sideTitles: SideTitles(
    showTitles: true,
    reservedSize: 24,
    interval: 1,
    getTitlesWidget: (v, _) {
      if (v % 1 != 0 || v > maxV) return const SizedBox();
      return Text(
        '${v.toInt()}',
        style: TextStyle(
          fontSize: 10,
          color: AppColors.ink(context).withValues(alpha: 0.4),
        ),
      );
    },
  ),
);

/// Always-on value labels above each bar (so the chart shows numbers too).
BarTouchData _valueLabels(BuildContext context) => BarTouchData(
  enabled: false,
  touchTooltipData: BarTouchTooltipData(
    getTooltipColor: (_) => Colors.transparent,
    tooltipPadding: EdgeInsets.zero,
    tooltipMargin: 2,
    getTooltipItem: (group, gi, rod, ri) => rod.toY <= 0
        ? null
        : BarTooltipItem(
            '${rod.toY.toInt()}',
            TextStyle(
              color: AppColors.ink(context),
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
  ),
);

/// Vertical bar chart: finished books per month (Jan..Dec).
class _MonthlyChart extends StatelessWidget {
  final List<int> months; // length 12
  const _MonthlyChart({required this.months});

  @override
  Widget build(BuildContext context) {
    final maxV = months.fold<int>(1, (m, v) => v > m ? v : m).toDouble();
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxV + 1,
        borderData: FlBorderData(show: false),
        gridData: const FlGridData(show: false),
        barTouchData: _valueLabels(context),
        titlesData: FlTitlesData(
          leftTitles: _countAxis(context, maxV),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (v, _) => Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Transform.rotate(
                  angle: -0.6,
                  child: Text(
                    _monthLabels[v.toInt() % 12],
                    style: TextStyle(
                      fontSize: 8,
                      color: AppColors.ink(context).withValues(alpha: 0.5),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        barGroups: [
          for (var i = 0; i < 12; i++)
            BarChartGroupData(
              x: i,
              showingTooltipIndicators: months[i] > 0 ? [0] : [],
              barRods: [
                BarChartRodData(
                  toY: months[i].toDouble(),
                  color: AppColors.mint,
                  width: 12,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

/// Multi-line chart: one line per year, finished books across the 12 months.
/// Lets you compare how each year's reading rose and fell month to month.
class _YearMonthlyChart extends StatelessWidget {
  final List<MapEntry<int, List<int>>> data; // oldest year first

  const _YearMonthlyChart({required this.data});

  // A distinct colour per year line (cycles if more than four years).
  static const _lineColors = [
    AppColors.lavender,
    AppColors.mint,
    AppColors.coral,
    AppColors.yellow,
  ];

  Color _colorFor(int index) => _lineColors[index % _lineColors.length];

  @override
  Widget build(BuildContext context) {
    final maxV = data
        .expand((e) => e.value)
        .fold<int>(1, (m, v) => v > m ? v : m)
        .toDouble();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Legend: a coloured dot + year for each line.
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Wrap(
            spacing: 16,
            runSpacing: 4,
            children: [
              for (var i = 0; i < data.length; i++)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: _colorFor(i),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${data[i].key}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink(context).withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
        SizedBox(
          height: 160,
          child: LineChart(
            LineChartData(
              minY: 0,
              maxY: maxV + 1,
              minX: 0,
              maxX: 11,
              borderData: FlBorderData(show: false),
              gridData: const FlGridData(show: false),
              lineTouchData: const LineTouchData(enabled: false),
              titlesData: FlTitlesData(
                leftTitles: _countAxis(context, maxV),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 1,
                    reservedSize: 28,
                    getTitlesWidget: (v, _) {
                      if (v % 1 != 0 || v < 0 || v > 11) {
                        return const SizedBox();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Transform.rotate(
                          angle: -0.6,
                          child: Text(
                            _monthLabels[v.toInt()],
                            style: TextStyle(
                              fontSize: 8,
                              color: AppColors.ink(
                                context,
                              ).withValues(alpha: 0.5),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              lineBarsData: [
                for (var i = 0; i < data.length; i++)
                  LineChartBarData(
                    spots: [
                      for (var m = 0; m < 12; m++)
                        FlSpot(m.toDouble(), data[i].value[m].toDouble()),
                    ],
                    isCurved: true,
                    preventCurveOverShooting: true,
                    color: _colorFor(i),
                    barWidth: 3,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, _, _, _) => FlDotCirclePainter(
                        radius: 3,
                        color: _colorFor(i),
                        strokeWidth: 2,
                        strokeColor: AppColors.surface(context),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 16),
    );
  }
}

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/deco_background.dart';
import '../auth/auth_provider.dart';
import 'profile_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  /// Years compared at once when specific years are picked. The filter governs
  /// the whole page — the status breakdown (each status by its own date), the
  /// average rating and the pace chart all follow the selection.
  static const _maxYears = 3;

  bool _all = true; // "All" (lifetime) is the default view
  List<int> _selected = const []; // specific years (used when _all is false)

  /// The effective years driving the page.
  List<int> _effective(List<int> allYears) {
    if (allYears.isEmpty) return const [];
    if (_all) return List<int>.of(allYears);
    return _selected.where(allYears.contains).toList()..sort();
  }

  void _selectAll() => setState(() => _all = true);

  void _toggle(int year, List<int> allYears) {
    setState(() {
      if (_all) {
        // Leaving "All" → start a fresh comparison with just this year.
        _all = false;
        _selected = [year];
        return;
      }
      final cur = List<int>.of(_effective(allYears));
      if (cur.contains(year)) {
        cur.remove(year); // may clear to none
      } else if (cur.length < _maxYears) {
        cur
          ..add(year)
          ..sort();
      }
      _selected = cur;
    });
  }

  /// "In 2026", "In 2024–2026" (consecutive) or "In 2023, 2025".
  String _periodLabel(List<int> years) {
    if (years.isEmpty) return 'Activity';
    if (years.length == 1) return 'In ${years.first}';
    final sorted = [...years]..sort();
    final consecutive = sorted.last - sorted.first == sorted.length - 1;
    return consecutive
        ? 'In ${sorted.first}–${sorted.last}'
        : 'In ${sorted.join(', ')}';
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final statsAsync = ref.watch(profileStatsProvider);
    final name =
        user?.userMetadata?['name'] as String? ?? user?.email ?? 'Reader';
    final avatarUrl =
        (user?.userMetadata?['avatar_url'] ?? user?.userMetadata?['picture'])
            as String?;

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
            final allYears = s.activityYears; // every year with any activity
            final hasFilter = allYears.length >= 2;
            final allMode = _all && hasFilter; // "All" only matters with ≥2 yrs
            final selected = _effective(allYears);
            // Status breakdown + avg rating follow the selected years.
            final wantN = s.wantInYears(selected);
            final readingN = s.readingInYears(selected);
            final finishedN = s.finishedInYears(selected);
            final avg = s.avgRatingInYears(selected);
            final hasPace = selected.any(
              (y) => (s.finishedCountByYear[y] ?? 0) > 0,
            );
            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _Header(name: name, email: user?.email, avatarUrl: avatarUrl),
                const SizedBox(height: 20),
                if (hasFilter) ...[
                  _YearFilter(
                    allYears: allYears,
                    selected: selected,
                    maxYears: _maxYears,
                    allSelected: allMode,
                    onSelectAll: _selectAll,
                    onToggle: (y) => _toggle(y, allYears),
                  ),
                  const SizedBox(height: 18),
                ],
                if (!allMode && selected.isEmpty)
                  _EmptyHint(
                    icon: allYears.isEmpty
                        ? Icons.menu_book_rounded
                        : Icons.touch_app_outlined,
                    text: allYears.isEmpty
                        ? 'No reading activity yet.'
                        : 'Pick a year above to see your reading activity.',
                  )
                else ...[
                  // Section header: the period + its average rating.
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: _SectionTitle(
                          allMode ? 'All time' : _periodLabel(selected),
                        ),
                      ),
                      if (avg != null) _AvgPill(avg),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _StatusBreakdown(
                    wantToRead: wantN,
                    reading: readingN,
                    finished: finishedN,
                  ),
                  if (hasPace) ...[
                    const SizedBox(height: 24),
                    _SectionTitle(
                      allMode ? 'Finished over the years' : 'Reading pace',
                    ),
                    const SizedBox(height: 12),
                    _ChartCard(
                      child: allMode
                          ? _AllTimeChart(data: s.finishedByYearMonth)
                          : _YearPaceChart(
                              data: s.finishedByYearMonth,
                              selected: selected,
                            ),
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
  final int wantToRead;
  final int reading;
  final int finished;
  const _StatusBreakdown({
    required this.wantToRead,
    required this.reading,
    required this.finished,
  });

  @override
  Widget build(BuildContext context) {
    final max = [
      reading,
      finished,
      wantToRead,
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
            label: 'Want to Read',
            value: wantToRead,
            max: max,
            color: AppColors.coral,
          ),
          const SizedBox(height: 12),
          _Bar(
            label: 'Reading',
            value: reading,
            max: max,
            color: AppColors.lavender,
          ),
          const SizedBox(height: 12),
          _Bar(
            label: 'Finished',
            value: finished,
            max: max,
            color: AppColors.mint,
          ),
        ],
      ),
    );
  }
}

/// Small rounded pill showing the average rating for the selected period.
class _AvgPill extends StatelessWidget {
  final double avg;
  const _AvgPill(this.avg);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.yellow.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, size: 16, color: AppColors.yellow),
          const SizedBox(width: 4),
          Text(
            '${avg.toStringAsFixed(1)} avg',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.ink(context),
            ),
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

/// Shown when no year is selected (or there is no activity at all).
class _EmptyHint extends StatelessWidget {
  final IconData icon;
  final String text;
  const _EmptyHint({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final ink = AppColors.ink(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, size: 36, color: AppColors.lavender),
          const SizedBox(height: 12),
          Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(color: ink.withValues(alpha: 0.6)),
          ),
        ],
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
double _countStep(double maxV) => maxV <= 6
    ? 1
    : maxV <= 15
    ? 2
    : maxV <= 40
    ? 5
    : 10;

AxisTitles _countAxis(BuildContext context, double maxV) {
  final step = _countStep(maxV);
  return AxisTitles(
    sideTitles: SideTitles(
      showTitles: true,
      reservedSize: 28,
      interval: step,
      getTitlesWidget: (v, _) {
        if (v % step != 0 || v > maxV) return const SizedBox();
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
}

/// Distinct colour per selected pace line — index = position in the sorted
/// selection, so the year chips and chart lines stay colour-matched.
const _paceColors = [AppColors.coral, AppColors.mint, AppColors.lavender];

Color _paceColor(List<int> selectedSorted, int year) {
  final i = selectedSorted.indexOf(year);
  return i < 0 ? AppColors.lavender : _paceColors[i % _paceColors.length];
}

/// Page-level year filter: pick up to [maxYears] years to compare. Selected
/// chips wear their pace-line colour (so the row doubles as the chart legend).
class _YearFilter extends StatelessWidget {
  final List<int> allYears; // ascending
  final List<int> selected; // ascending
  final int maxYears;
  final bool allSelected; // "All" (lifetime) active
  final VoidCallback onSelectAll;
  final void Function(int year) onToggle;

  const _YearFilter({
    required this.allYears,
    required this.selected,
    required this.maxYears,
    required this.allSelected,
    required this.onSelectAll,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final atMax = !allSelected && selected.length >= maxYears;
    final years = allYears.reversed.toList(); // newest first
    // A single horizontally-scrolling row: "All" then the years, so any number
    // of years fits on one line (newest first; older ones scroll into view).
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 2),
        itemCount: years.length + 1,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          if (i == 0) {
            return Center(
              child: _ChipPill(
                label: 'All',
                selected: allSelected,
                color: allSelected ? AppColors.ink(context) : null,
                showDot: false,
                enabled: true,
                onTap: onSelectAll,
              ),
            );
          }
          final y = years[i - 1];
          final sel = !allSelected && selected.contains(y);
          return Center(
            child: _ChipPill(
              label: '$y',
              selected: sel,
              color: sel ? _paceColor(selected, y) : null,
              enabled: allSelected || selected.contains(y) || !atMax,
              onTap: () => onToggle(y),
            ),
          );
        },
      ),
    );
  }
}

/// Cumulative "reading pace" line chart — one line per selected year.
class _YearPaceChart extends StatelessWidget {
  final List<MapEntry<int, List<int>>> data; // all years
  final List<int> selected; // ascending years to draw

  const _YearPaceChart({required this.data, required this.selected});

  @override
  Widget build(BuildContext context) {
    final byYear = {for (final e in data) e.key: e.value};
    final shown = selected.where(byYear.containsKey).toList()..sort();
    // Cumulative chart: the highest point a line reaches is the selected year
    // with the most finished books (its end-of-year running total).
    final maxV = shown
        .map((y) => byYear[y]!.fold<int>(0, (a, b) => a + b))
        .fold<int>(1, (m, v) => v > m ? v : m)
        .toDouble();
    return SizedBox(
      height: 170,
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
                  if (v % 1 != 0 || v < 0 || v > 11) return const SizedBox();
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Transform.rotate(
                      angle: -0.6,
                      child: Text(
                        _monthLabels[v.toInt()],
                        style: TextStyle(
                          fontSize: 8,
                          color: AppColors.ink(context).withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          lineBarsData: [
            for (final y in shown)
              LineChartBarData(
                spots: [
                  // Running total of finished books up to each month.
                  for (var m = 0; m < 12; m++)
                    FlSpot(
                      m.toDouble(),
                      byYear[y]!
                          .take(m + 1)
                          .fold<int>(0, (a, b) => a + b)
                          .toDouble(),
                    ),
                ],
                isCurved: true,
                preventCurveOverShooting: true,
                color: _paceColor(shown, y),
                barWidth: 3,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, _, _, _) => FlDotCirclePainter(
                    radius: 3,
                    color: _paceColor(shown, y),
                    strokeWidth: 2,
                    strokeColor: AppColors.surface(context),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// A toggleable year pill for the reading-pace chart. When selected it wears
/// its line colour (so it doubles as the legend); disabled when the max number
/// of years is already chosen.
/// All-time view: cumulative total of finished books across the years
/// (x-axis = years, one rising line).
class _AllTimeChart extends StatelessWidget {
  final List<MapEntry<int, List<int>>> data; // per-year monthly, ascending
  const _AllTimeChart({required this.data});

  @override
  Widget build(BuildContext context) {
    final years = data.map((e) => e.key).toList()..sort();
    final totalByYear = {
      for (final e in data) e.key: e.value.fold<int>(0, (a, b) => a + b),
    };
    var run = 0;
    final spots = <FlSpot>[];
    for (var i = 0; i < years.length; i++) {
      run += totalByYear[years[i]] ?? 0;
      spots.add(FlSpot(i.toDouble(), run.toDouble()));
    }
    final maxV = (run < 1 ? 1 : run).toDouble();
    return SizedBox(
      height: 170,
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: maxV + 1,
          minX: 0,
          maxX: (years.length - 1).toDouble(),
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
                reservedSize: 24,
                getTitlesWidget: (v, _) {
                  final i = v.toInt();
                  if (v % 1 != 0 || i < 0 || i >= years.length) {
                    return const SizedBox();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      '${years[i]}',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.ink(context).withValues(alpha: 0.5),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              preventCurveOverShooting: true,
              color: AppColors.coral,
              barWidth: 3,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, _, _, _) => FlDotCirclePainter(
                  radius: 3,
                  color: AppColors.coral,
                  strokeWidth: 2,
                  strokeColor: AppColors.surface(context),
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                color: AppColors.coral.withValues(alpha: 0.12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChipPill extends StatelessWidget {
  final String label;
  final bool selected;
  final Color? color;
  final bool enabled;
  final bool showDot;
  final VoidCallback onTap;

  const _ChipPill({
    required this.label,
    required this.selected,
    required this.color,
    required this.enabled,
    required this.onTap,
    this.showDot = true,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.lavender;
    final ink = AppColors.ink(context);
    return Opacity(
      opacity: enabled ? 1 : 0.35,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? c.withValues(alpha: 0.18) : Colors.transparent,
            border: Border.all(
              color: selected ? c : ink.withValues(alpha: 0.2),
              width: selected ? 1.5 : 1,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selected && showDot) ...[
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(color: c, shape: BoxShape.circle),
                ),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: ink.withValues(alpha: selected ? 0.9 : 0.6),
                ),
              ),
            ],
          ),
        ),
      ),
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

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/user_book.dart';
import '../shelf/shelf_provider.dart';

class ProfileStats {
  final int reading;
  final int finished;
  final int wantToRead;
  final int rated;
  final int reviewed;
  final double? avgRating;
  final List<UserBook> recentReviews;

  /// Finished-book counts per year, sorted newest year first.
  final List<MapEntry<int, int>> finishedByYear;

  /// The year shown in the monthly chart and its 12 month counts (Jan..Dec).
  final int monthlyYear;
  final List<int> finishedByMonth;

  /// Per-year monthly breakdown (year → 12 month counts), oldest year first.
  /// Powers the multi-line "by month, per year" comparison chart.
  final List<MapEntry<int, List<int>>> finishedByYearMonth;

  /// Year-scoped aggregates so the headline metrics can follow the year filter.
  final Map<int, int> finishedCountByYear;
  final Map<int, double> ratingSumByYear;
  final Map<int, int> ratingCountByYear;

  const ProfileStats({
    required this.reading,
    required this.finished,
    required this.wantToRead,
    required this.rated,
    required this.reviewed,
    required this.avgRating,
    required this.recentReviews,
    required this.finishedByYear,
    required this.monthlyYear,
    required this.finishedByMonth,
    required this.finishedByYearMonth,
    required this.finishedCountByYear,
    required this.ratingSumByYear,
    required this.ratingCountByYear,
  });

  int get total => reading + finished + wantToRead;

  /// Finished books across the given years.
  int finishedInYears(Iterable<int> years) =>
      years.fold(0, (a, y) => a + (finishedCountByYear[y] ?? 0));

  /// Average rating of books finished within the given years (null if none).
  double? avgRatingInYears(Iterable<int> years) {
    var sum = 0.0;
    var count = 0;
    for (final y in years) {
      sum += ratingSumByYear[y] ?? 0;
      count += ratingCountByYear[y] ?? 0;
    }
    return count == 0 ? null : sum / count;
  }
}

/// Computes profile statistics from the user's shelf (pure mapping).
ProfileStats computeStats(List<UserBook> books) {
  final rated = books.where((b) => b.rating != null).toList();
  final reviewed =
      books.where((b) => b.review != null && b.review!.isNotEmpty).toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  final avg = rated.isEmpty
      ? null
      : rated.map((b) => b.rating!).reduce((a, b) => a + b) / rated.length;

  final byYear = <int, int>{};
  for (final b in books.where((b) => b.status == ReadingStatus.finished)) {
    final year = (b.dateFinished ?? b.createdAt).year;
    byYear[year] = (byYear[year] ?? 0) + 1;
  }
  final byYearSorted = byYear.entries.toList()
    ..sort((a, b) => b.key.compareTo(a.key));

  // Monthly breakdown is always the current calendar year.
  final monthlyYear = DateTime.now().year;
  final byMonth = List<int>.filled(12, 0);
  for (final b in books.where(
    (b) =>
        b.status == ReadingStatus.finished &&
        (b.dateFinished ?? b.createdAt).year == monthlyYear,
  )) {
    final m = (b.dateFinished ?? b.createdAt).month; // 1..12
    byMonth[m - 1]++;
  }

  // Per-year monthly breakdown + per-year rating aggregates.
  final byYearMonth = <int, List<int>>{};
  final ratingSumByYear = <int, double>{};
  final ratingCountByYear = <int, int>{};
  for (final b in books.where((b) => b.status == ReadingStatus.finished)) {
    final d = b.dateFinished ?? b.createdAt;
    final list = byYearMonth.putIfAbsent(d.year, () => List<int>.filled(12, 0));
    list[d.month - 1]++;
    if (b.rating != null) {
      ratingSumByYear[d.year] = (ratingSumByYear[d.year] ?? 0) + b.rating!;
      ratingCountByYear[d.year] = (ratingCountByYear[d.year] ?? 0) + 1;
    }
  }
  final byYearMonthSorted = byYearMonth.entries.toList()
    ..sort((a, b) => a.key.compareTo(b.key)); // oldest year first

  return ProfileStats(
    reading: books.where((b) => b.status == ReadingStatus.reading).length,
    finished: books.where((b) => b.status == ReadingStatus.finished).length,
    wantToRead: books.where((b) => b.status == ReadingStatus.wantToRead).length,
    rated: rated.length,
    reviewed: reviewed.length,
    avgRating: avg,
    recentReviews: reviewed.take(10).toList(),
    finishedByYear: byYearSorted,
    monthlyYear: monthlyYear,
    finishedByMonth: byMonth,
    finishedByYearMonth: byYearMonthSorted,
    finishedCountByYear: byYear,
    ratingSumByYear: ratingSumByYear,
    ratingCountByYear: ratingCountByYear,
  );
}

final profileStatsProvider = Provider<AsyncValue<ProfileStats>>((ref) {
  return ref.watch(shelfBooksProvider).whenData(computeStats);
});

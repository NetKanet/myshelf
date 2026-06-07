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

  const ProfileStats({
    required this.reading,
    required this.finished,
    required this.wantToRead,
    required this.rated,
    required this.reviewed,
    required this.avgRating,
    required this.recentReviews,
  });

  int get total => reading + finished + wantToRead;
}

/// Computes profile statistics from the user's shelf (pure mapping).
ProfileStats computeStats(List<UserBook> books) {
  final rated = books.where((b) => b.rating != null).toList();
  final reviewed = books
      .where((b) => b.review != null && b.review!.isNotEmpty)
      .toList()
    ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  final avg = rated.isEmpty
      ? null
      : rated.map((b) => b.rating!).reduce((a, b) => a + b) / rated.length;

  return ProfileStats(
    reading: books.where((b) => b.status == ReadingStatus.reading).length,
    finished: books.where((b) => b.status == ReadingStatus.finished).length,
    wantToRead:
        books.where((b) => b.status == ReadingStatus.wantToRead).length,
    rated: rated.length,
    reviewed: reviewed.length,
    avgRating: avg,
    recentReviews: reviewed.take(10).toList(),
  );
}

final profileStatsProvider = Provider<AsyncValue<ProfileStats>>((ref) {
  return ref.watch(shelfBooksProvider).whenData(computeStats);
});

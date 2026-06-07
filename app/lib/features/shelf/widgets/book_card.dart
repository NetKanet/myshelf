import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/book_cover.dart';
import '../../../models/user_book.dart';

class BookCard extends StatelessWidget {
  final UserBook userBook;
  final VoidCallback onTap;
  final bool showStatus;

  const BookCard({
    super.key,
    required this.userBook,
    required this.onTap,
    this.showStatus = true,
  });

  @override
  Widget build(BuildContext context) {
    final book = userBook.book;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface(context),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.navy.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            BookCover(
              coverUrl: book?.coverUrl,
              seed: book?.id ?? userBook.id,
              width: 56,
              height: 80,
              radius: 8,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book?.title ?? 'Unknown Title',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontSize: 15),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (book?.author != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      book!.author!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.ink(context).withValues(alpha: 0.6),
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (showStatus) ...[
                    const SizedBox(height: 8),
                    _StatusBadge(userBook: userBook),
                  ],
                  if (userBook.rating != null) ...[
                    const SizedBox(height: 6),
                    _MiniStars(rating: userBook.rating!),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.lavender),
          ],
        ),
      ),
    );
  }
}


class _StatusBadge extends StatelessWidget {
  final UserBook userBook;
  const _StatusBadge({required this.userBook});

  @override
  Widget build(BuildContext context) {
    final (color, text) = switch (userBook.status) {
      ReadingStatus.finished => (
          AppColors.mint,
          userBook.dateFinished != null
              ? '✓ Finished ${DateFormat('MMM d, yyyy').format(userBook.dateFinished!)}'
              : '✓ Finished'
        ),
      ReadingStatus.reading => (AppColors.lavender, 'Reading'),
      ReadingStatus.wantToRead => (AppColors.coral, 'Want to Read'),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _MiniStars extends StatelessWidget {
  final double rating;
  const _MiniStars({required this.rating});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ...List.generate(5, (i) {
          final pos = i + 1;
          final icon = rating >= pos
              ? Icons.star_rounded
              : rating >= pos - 0.5
                  ? Icons.star_half_rounded
                  : Icons.star_outline_rounded;
          return Icon(icon,
              size: 14,
              color: rating >= pos - 0.5
                  ? AppColors.yellow
                  : AppColors.lavender);
        }),
        const SizedBox(width: 4),
        Text(
          rating.toStringAsFixed(rating == rating.roundToDouble() ? 0 : 1),
          style: TextStyle(
            fontSize: 11,
            color: AppColors.ink(context).withValues(alpha: 0.5),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

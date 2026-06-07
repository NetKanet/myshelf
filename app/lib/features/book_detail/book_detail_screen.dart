import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/book_cover.dart';
import '../../core/widgets/deco_background.dart';
import '../../models/user_book.dart';
import '../shelf/shelf_provider.dart';
import 'book_detail_provider.dart';
import 'widgets/delete_confirm_dialog.dart';

class BookDetailScreen extends ConsumerWidget {
  final String userBookId;
  const BookDetailScreen({super.key, required this.userBookId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(bookDetailProvider(userBookId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Detail'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.coral),
            tooltip: 'Remove from shelf',
            onPressed: () => _confirmDelete(context, ref),
          ),
        ],
      ),
      body: DecoBackground(
        child: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (userBook) {
          if (userBook == null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/shelf');
              }
            });
            return const SizedBox.shrink();
          }
          return _BookDetailContent(
            userBook: userBook,
            onSave: (status, ds, df, rating, review) async {
              await ref
                  .read(bookDetailProvider(userBookId).notifier)
                  .saveAll(
                    status: status,
                    dateStarted: ds,
                    dateFinished: df,
                    rating: rating,
                    review: review,
                  );
              ref.invalidate(shelfBooksProvider);
            },
          );
        },
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => const DeleteConfirmDialog(),
    );
    if (confirmed == true && context.mounted) {
      await ref.read(bookDetailProvider(userBookId).notifier).deleteFromShelf();
      ref.invalidate(shelfBooksProvider);
      if (context.mounted) {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/shelf');
        }
      }
    }
  }
}

typedef _SaveCb = Future<void> Function(
  ReadingStatus status,
  DateTime? dateStarted,
  DateTime? dateFinished,
  double? rating,
  String? review,
);

class _BookDetailContent extends StatefulWidget {
  final UserBook userBook;
  final _SaveCb onSave;
  const _BookDetailContent({required this.userBook, required this.onSave});

  @override
  State<_BookDetailContent> createState() => _BookDetailContentState();
}

class _BookDetailContentState extends State<_BookDetailContent> {
  late ReadingStatus _status;
  DateTime? _dateStarted;
  DateTime? _dateFinished;
  double? _rating;
  final _review = TextEditingController();
  bool _saving = false;
  bool _descExpanded = false;

  bool get _dirty =>
      _status != widget.userBook.status ||
      _dateStarted != widget.userBook.dateStarted ||
      _dateFinished != widget.userBook.dateFinished ||
      _rating != widget.userBook.rating ||
      _review.text != (widget.userBook.review ?? '');

  @override
  void initState() {
    super.initState();
    _sync();
  }

  void _sync() {
    _status = widget.userBook.status;
    _dateStarted = widget.userBook.dateStarted;
    _dateFinished = widget.userBook.dateFinished;
    _rating = widget.userBook.rating;
    _review.text = widget.userBook.review ?? '';
  }

  @override
  void dispose() {
    _review.dispose();
    super.dispose();
  }

  void _onStatus(ReadingStatus s) {
    final today = DateTime.now();
    setState(() {
      _status = s;
      // Dates auto-fill/clear (FR-021). Rating/review are NOT cleared (Q3).
      if (s == ReadingStatus.wantToRead) {
        _dateStarted = null;
        _dateFinished = null;
      } else if (s == ReadingStatus.reading) {
        _dateStarted ??= today;
        _dateFinished = null;
      } else {
        _dateStarted ??= today;
        _dateFinished ??= today;
      }
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await widget.onSave(
        _status,
        _dateStarted,
        _dateFinished,
        _rating,
        _review.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Saved!'),
            backgroundColor: AppColors.mint,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final book = widget.userBook.book;
    final isFinished = _status == ReadingStatus.finished;
    final showDates = _status != ReadingStatus.wantToRead;

    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final leave = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Unsaved changes'),
            content: const Text('Leave without saving?'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel')),
              TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Leave',
                      style: TextStyle(color: AppColors.coral))),
            ],
          ),
        );
        if (leave == true && context.mounted) Navigator.pop(context);
      },
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      BookCover(
                        coverUrl: book?.coverUrl,
                        seed: book?.id ?? widget.userBook.bookId,
                        width: 110,
                        height: 160,
                        radius: 12,
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(book?.title ?? 'Unknown Title',
                                style:
                                    Theme.of(context).textTheme.titleLarge),
                            if (book?.author != null) ...[
                              const SizedBox(height: 6),
                              Text(book!.author!,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                          color: AppColors.navy
                                              .withValues(alpha: 0.6))),
                            ],
                            if (book?.publisher != null) ...[
                              const SizedBox(height: 4),
                              Text(book!.publisher!,
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.navy
                                          .withValues(alpha: 0.4))),
                            ],
                            const SizedBox(height: 8),
                            Wrap(spacing: 8, children: [
                              if (book?.publishedYear != null)
                                _Chip(label: '${book!.publishedYear}'),
                              if (book?.pageCount != null)
                                _Chip(
                                    icon: Icons.menu_book_outlined,
                                    label: '${book!.pageCount} pages'),
                            ]),
                            const SizedBox(height: 12),
                            // Rating sits next to the cover (any status).
                            _StarRating(
                                rating: _rating,
                                size: 26,
                                onChanged: (r) =>
                                    setState(() => _rating = r)),
                            if (_rating != null)
                              GestureDetector(
                                onTap: () => setState(() => _rating = null),
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text('Clear rating',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: AppColors.navy
                                              .withValues(alpha: 0.5))),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  _label(context, 'Reading Status'),
                  const SizedBox(height: 12),
                  _StatusSelector(current: _status, onChanged: _onStatus),
                  if (showDates) ...[
                    const SizedBox(height: 24),
                    _label(context, 'Date Started'),
                    const SizedBox(height: 8),
                    _DatePicker(
                        date: _dateStarted,
                        onChanged: (d) => setState(() => _dateStarted = d)),
                  ],
                  if (isFinished) ...[
                    const SizedBox(height: 24),
                    _label(context, 'Date Finished'),
                    const SizedBox(height: 8),
                    _DatePicker(
                        date: _dateFinished,
                        onChanged: (d) => setState(() => _dateFinished = d)),
                  ],
                  // Review is available for any status.
                  const SizedBox(height: 24),
                  _label(context, 'Review'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _review,
                    maxLines: 4,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Your thoughts about this book…',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: AppColors.lavender),
                      ),
                    ),
                  ),
                  if (book?.description != null &&
                      book!.description!.isNotEmpty) ...[
                    const SizedBox(height: 28),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _label(context, 'Description'),
                        TextButton(
                          onPressed: () => setState(
                              () => _descExpanded = !_descExpanded),
                          child: Text(_descExpanded ? 'Less' : 'More'),
                        ),
                      ],
                    ),
                    Text(
                      book.description!,
                      maxLines: _descExpanded ? null : 3,
                      overflow: _descExpanded ? null : TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.navy.withValues(alpha: 0.7)),
                    ),
                  ],
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.navy,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('Save',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 16)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(BuildContext context, String text) => Text(text,
      style:
          Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 16));
}

class _Chip extends StatelessWidget {
  final IconData? icon;
  final String label;
  const _Chip({this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.lavender.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null) ...[
          Icon(icon, size: 12, color: AppColors.navy.withValues(alpha: 0.5)),
          const SizedBox(width: 4),
        ],
        Text(label,
            style: TextStyle(
                fontSize: 12, color: AppColors.navy.withValues(alpha: 0.5))),
      ]),
    );
  }
}

class _StatusSelector extends StatelessWidget {
  final ReadingStatus current;
  final void Function(ReadingStatus) onChanged;
  const _StatusSelector({required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: ReadingStatus.values.map((status) {
        final active = status == current;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: GestureDetector(
              onTap: active ? null : () => onChanged(status),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: active ? AppColors.yellow : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: active ? AppColors.yellow : AppColors.lavender,
                      width: active ? 2 : 1),
                ),
                child: Text(
                  status.label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                    color: active
                        ? AppColors.navy
                        : AppColors.navy.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _DatePicker extends StatelessWidget {
  final DateTime? date;
  final void Function(DateTime) onChanged;
  const _DatePicker({this.date, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date ?? DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime.now(),
        );
        if (picked != null) onChanged(picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.lavender),
        ),
        child: Row(children: [
          const Icon(Icons.calendar_today_outlined,
              size: 18, color: AppColors.navy),
          const SizedBox(width: 10),
          Text(
            date != null
                ? DateFormat('MMMM d, yyyy').format(date!)
                : 'Pick a date',
            style: TextStyle(
                color: date != null
                    ? AppColors.navy
                    : AppColors.navy.withValues(alpha: 0.4)),
          ),
        ]),
      ),
    );
  }
}

class _StarRating extends StatelessWidget {
  final double? rating;
  final void Function(double) onChanged;
  final double size;
  const _StarRating({this.rating, required this.onChanged, this.size = 36});

  @override
  Widget build(BuildContext context) {
    final value = rating ?? 0;
    return Row(
      children: List.generate(5, (i) {
        final pos = i + 1;
        final icon = value >= pos
            ? Icons.star_rounded
            : value >= pos - 0.5
                ? Icons.star_half_rounded
                : Icons.star_outline_rounded;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (d) {
            final leftHalf = d.localPosition.dx < size / 2;
            onChanged(leftHalf ? pos - 0.5 : pos.toDouble());
          },
          child: Padding(
            padding: const EdgeInsets.only(right: 3),
            child: Icon(icon,
                size: size,
                color: value >= pos - 0.5
                    ? AppColors.yellow
                    : AppColors.lavender),
          ),
        );
      }),
    );
  }
}

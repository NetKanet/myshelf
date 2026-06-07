import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../models/user_book.dart';
import 'shelf_provider.dart';
import 'widgets/book_card.dart';

class ShelfScreen extends ConsumerWidget {
  const ShelfScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(shelfFilterProvider);
    final shelf = ref.watch(filteredShelfProvider);
    final filtering = filter != ShelfFilter.all;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Shelf'),
        actions: [
          IconButton(
            tooltip: 'Filter',
            icon: Icon(
              filtering
                  ? Icons.filter_list_rounded
                  : Icons.filter_list_outlined,
              color: filtering ? AppColors.navy : AppColors.navy,
            ),
            onPressed: () => _showFilterSheet(context, ref, filter),
          ),
        ],
      ),
      body: Column(
        children: [
          if (filtering) _ActiveFilter(filter: filter),
          Expanded(
            child: shelf.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (books) {
                if (books.isEmpty) return _EmptyState(filter: filter);
                final items = groupShelf(books);
                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(shelfBooksProvider),
                  child: ListView.builder(
                    padding: const EdgeInsets.only(top: 4, bottom: 24),
                    itemCount: items.length,
                    itemBuilder: (_, i) {
                      final item = items[i];
                      if (item is ShelfSection) {
                        return _SectionHeader(title: item.title);
                      }
                      final ub = item as UserBook;
                      return BookCard(
                        userBook: ub,
                        // Status is implied by the section header, so hide the
                        // per-card badge.
                        showStatus: false,
                        onTap: () => context.push('/book/${ub.id}'),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterSheet(
      BuildContext context, WidgetRef ref, ShelfFilter current) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Text('Filter shelf',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontSize: 16)),
            const SizedBox(height: 8),
            ...ShelfFilter.values.map((f) {
              final selected = f == current;
              return ListTile(
                leading: Icon(_iconFor(f),
                    color: selected ? AppColors.navy : AppColors.lavender),
                title: Text(f.label,
                    style: TextStyle(
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w500,
                        color: AppColors.navy)),
                trailing: selected
                    ? const Icon(Icons.check_rounded, color: AppColors.navy)
                    : null,
                onTap: () {
                  ref.read(shelfFilterProvider.notifier).state = f;
                  Navigator.pop(context);
                },
              );
            }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  IconData _iconFor(ShelfFilter f) => switch (f) {
        ShelfFilter.all => Icons.apps_rounded,
        ShelfFilter.reading => Icons.menu_book_rounded,
        ShelfFilter.finished => Icons.check_circle_outline_rounded,
        ShelfFilter.wantToRead => Icons.bookmark_border_rounded,
      };
}

/// Small bar showing the active filter with a clear (✕) action.
class _ActiveFilter extends ConsumerWidget {
  final ShelfFilter filter;
  const _ActiveFilter({required this.filter});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: InputChip(
          label: Text(filter.label),
          backgroundColor: AppColors.yellow.withValues(alpha: 0.25),
          side: const BorderSide(color: AppColors.yellow),
          labelStyle: const TextStyle(
              color: AppColors.navy, fontWeight: FontWeight.w600),
          deleteIcon: const Icon(Icons.close_rounded, size: 18),
          onDeleted: () =>
              ref.read(shelfFilterProvider.notifier).state = ShelfFilter.all,
        ),
      ),
    );
  }
}

/// Year / status section divider in the shelf list.
class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.navy,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              height: 2,
              decoration: BoxDecoration(
                color: AppColors.lavender.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final ShelfFilter filter;
  const _EmptyState({required this.filter});

  @override
  Widget build(BuildContext context) {
    final msg = filter == ShelfFilter.all
        ? 'Your shelf is empty.\nTap + below to add a book.'
        : 'No “${filter.label}” books yet.';
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.menu_book_rounded,
                size: 64, color: AppColors.lavender),
            const SizedBox(height: 16),
            Text(
              msg,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.navy.withValues(alpha: 0.6),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

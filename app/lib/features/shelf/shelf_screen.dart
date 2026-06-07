import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import 'shelf_provider.dart';
import 'widgets/book_card.dart';

class ShelfScreen extends ConsumerWidget {
  const ShelfScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(shelfFilterProvider);
    final shelf = ref.watch(filteredShelfProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My Shelf')),
      body: Column(
        children: [
          _FilterChips(active: filter),
          Expanded(
            child: shelf.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (books) {
                if (books.isEmpty) {
                  return _EmptyState(filter: filter);
                }
                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(shelfBooksProvider),
                  child: ListView.builder(
                    padding: const EdgeInsets.only(top: 4, bottom: 88),
                    itemCount: books.length,
                    itemBuilder: (_, i) => BookCard(
                      userBook: books[i],
                      onTap: () => context.push('/book/${books[i].id}'),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChips extends ConsumerWidget {
  final ShelfFilter active;
  const _FilterChips({required this.active});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      height: 52,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: ShelfFilter.values.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final f = ShelfFilter.values[i];
          final selected = f == active;
          return ChoiceChip(
            label: Text(f.label),
            selected: selected,
            onSelected: (_) =>
                ref.read(shelfFilterProvider.notifier).state = f,
            showCheckmark: false,
            selectedColor: AppColors.yellow,
            backgroundColor: Colors.white,
            labelStyle: TextStyle(
              color: AppColors.navy,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: selected ? AppColors.yellow : AppColors.lavender,
              ),
            ),
          );
        },
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

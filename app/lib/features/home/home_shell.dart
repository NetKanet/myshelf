import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../profile/profile_screen.dart';
import '../scan/scan_provider.dart';
import '../scan/widgets/manual_input_dialog.dart';
import '../shelf/shelf_provider.dart';
import '../shelf/shelf_screen.dart';
import 'widgets/add_sheet.dart';

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _tab = 0; // 0 = Shelf, 1 = Profile

  Future<void> _onAdd() async {
    final action = await showAddSheet(context);
    if (!mounted) return;
    switch (action) {
      case AddAction.scan:
        context.push('/scan');
      case AddAction.manual:
        await _addManual();
      case AddAction.batchScan:
      case AddAction.search:
      case null:
        break;
    }
  }

  Future<void> _addManual() async {
    final input = await showDialog<ManualBookInput>(
      context: context,
      builder: (_) => const ManualInputDialog(),
    );
    if (input == null) return;
    final id = await ref
        .read(scanProvider.notifier)
        .addManual(title: input.title, author: input.author);
    ref.invalidate(shelfBooksProvider);
    if (id != null && mounted) context.push('/book/$id');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _tab,
        children: const [ShelfScreen(), ProfileScreen()],
      ),
      bottomNavigationBar: _BottomBar(
        index: _tab,
        onShelf: () => setState(() => _tab = 0),
        onProfile: () => setState(() => _tab = 1),
        onAdd: _onAdd,
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  final int index;
  final VoidCallback onShelf;
  final VoidCallback onProfile;
  final VoidCallback onAdd;

  const _BottomBar({
    required this.index,
    required this.onShelf,
    required this.onProfile,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: AppColors.navy.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _NavIcon(
              icon: Icons.library_books_rounded,
              label: 'Shelf',
              active: index == 0,
              onTap: onShelf,
            ),
            GestureDetector(
              onTap: onAdd,
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.yellow,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.add_rounded,
                    color: AppColors.navy, size: 30),
              ),
            ),
            _NavIcon(
              icon: Icons.person_rounded,
              label: 'Profile',
              active: index == 1,
              onTap: onProfile,
            ),
          ],
        ),
      ),
    );
  }
}

class _NavIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _NavIcon({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color =
        active ? AppColors.navy : AppColors.navy.withValues(alpha: 0.35);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 80,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(
                    fontSize: 11,
                    color: color,
                    fontWeight:
                        active ? FontWeight.w700 : FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

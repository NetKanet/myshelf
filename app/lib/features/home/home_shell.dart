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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: 0.10),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 70,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _NavIcon(
                icon: Icons.library_books_rounded,
                label: 'Shelf',
                active: index == 0,
                onTap: onShelf,
              ),
              _AddButton(onTap: onAdd),
              _NavIcon(
                icon: Icons.person_rounded,
                label: 'Profile',
                active: index == 1,
                onTap: onProfile,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  final VoidCallback onTap;
  const _AddButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 58,
        height: 58,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.yellow, Color(0xFFFFC93D)],
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.yellow.withValues(alpha: 0.55),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(Icons.add_rounded, color: AppColors.navy, size: 32),
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
        active ? AppColors.navy : AppColors.navy.withValues(alpha: 0.30);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 88,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
              decoration: BoxDecoration(
                color: active
                    ? AppColors.yellow.withValues(alpha: 0.22)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 3),
            Text(label,
                style: TextStyle(
                    fontSize: 11,
                    color: color,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

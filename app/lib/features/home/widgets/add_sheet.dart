import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

enum AddAction { scan, manual }

/// Bottom sheet shown by the center "+" nav button.
Future<AddAction?> showAddSheet(BuildContext context) {
  return showModalBottomSheet<AddAction>(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.lavender,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 8),
          _Item(
            icon: Icons.qr_code_scanner_rounded,
            label: 'Scan book ISBN',
            onTap: () => Navigator.pop(context, AddAction.scan),
          ),
          _Item(
            icon: Icons.edit_outlined,
            label: 'Add new book manually',
            onTap: () => Navigator.pop(context, AddAction.manual),
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}

class _Item extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _Item({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.navy),
      title: Text(label,
          style:
              const TextStyle(fontWeight: FontWeight.w600, color: AppColors.navy)),
      onTap: onTap,
    );
  }
}

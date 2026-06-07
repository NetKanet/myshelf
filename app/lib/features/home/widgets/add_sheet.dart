import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

enum AddAction { scan, batchScan, search, manual }

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
            icon: Icons.document_scanner_outlined,
            label: 'Batch scan books',
            subtitle: 'Coming soon',
            onTap: null,
          ),
          _Item(
            icon: Icons.search_rounded,
            label: 'Search new books',
            subtitle: 'Coming soon',
            onTap: null,
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
  final String? subtitle;
  final VoidCallback? onTap;

  const _Item({
    required this.icon,
    required this.label,
    this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    return ListTile(
      enabled: !disabled,
      leading: Icon(icon,
          color: disabled ? AppColors.lavender : AppColors.navy),
      title: Text(label,
          style: TextStyle(
              fontWeight: FontWeight.w600,
              color: disabled
                  ? AppColors.navy.withValues(alpha: 0.4)
                  : AppColors.navy)),
      subtitle: subtitle != null
          ? Text(subtitle!,
              style: const TextStyle(fontSize: 12, color: AppColors.lavender))
          : null,
      onTap: onTap,
    );
  }
}

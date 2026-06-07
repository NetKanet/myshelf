import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Confirmation before removing a book from the shelf. Returns true on confirm.
class DeleteConfirmDialog extends StatelessWidget {
  const DeleteConfirmDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Remove from shelf?'),
      content: const Text('This deletes the book from your shelf.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Remove', style: TextStyle(color: AppColors.coral)),
        ),
      ],
    );
  }
}

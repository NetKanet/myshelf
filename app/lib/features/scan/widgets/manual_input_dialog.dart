import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Result of the manual-entry dialog.
class ManualBookInput {
  final String title;
  final String? author;
  const ManualBookInput({required this.title, this.author});
}

/// Asks for title + author when an ISBN can't be found.
class ManualInputDialog extends StatefulWidget {
  final String? isbn;
  const ManualInputDialog({super.key, this.isbn});

  @override
  State<ManualInputDialog> createState() => _ManualInputDialogState();
}

class _ManualInputDialogState extends State<ManualInputDialog> {
  final _title = TextEditingController();
  final _author = TextEditingController();

  @override
  void dispose() {
    _title.dispose();
    _author.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Add book manually'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.isbn != null && widget.isbn!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                'ISBN ${widget.isbn} wasn’t found. Enter the details:',
                style: TextStyle(
                    color: AppColors.navy.withValues(alpha: 0.6),
                    fontSize: 13),
              ),
            ),
          TextField(
            controller: _title,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Title *'),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _author,
            decoration: const InputDecoration(labelText: 'Author'),
            textCapitalization: TextCapitalization.words,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final title = _title.text.trim();
            if (title.isEmpty) return;
            Navigator.pop(
              context,
              ManualBookInput(
                title: title,
                author: _author.text.trim().isEmpty
                    ? null
                    : _author.text.trim(),
              ),
            );
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}

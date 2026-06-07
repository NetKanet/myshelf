import 'package:flutter/material.dart';

/// Placeholder — full detail screen is built in US4.
class BookDetailScreen extends StatelessWidget {
  final String userBookId;
  const BookDetailScreen({super.key, required this.userBookId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Book Detail')),
      body: Center(child: Text('Detail for $userBookId — coming in US4')),
    );
  }
}

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Colorful gradient placeholders (from the design mockup) used when a book
/// has no cover image. A stable [seed] picks the same gradient every time.
const List<List<Color>> _gradients = [
  [Color(0xFF667EEA), Color(0xFF764BA2)],
  [Color(0xFFF093FB), Color(0xFFF5576C)],
  [Color(0xFF4FACFE), Color(0xFF00F2FE)],
  [Color(0xFF43E97B), Color(0xFF38F9D7)],
  [Color(0xFFFA709A), Color(0xFFFEE140)],
];

/// Book cover: the network image when available, otherwise a deterministic
/// colorful gradient with a bookmark glyph.
class BookCover extends StatelessWidget {
  final String? coverUrl;
  final String seed;
  final double width;
  final double height;
  final double radius;

  const BookCover({
    super.key,
    required this.coverUrl,
    required this.seed,
    required this.width,
    required this.height,
    this.radius = 10,
  });

  @override
  Widget build(BuildContext context) {
    final placeholder = _GradientPlaceholder(
      seed: seed,
      width: width,
      height: height,
      radius: radius,
    );
    if (coverUrl == null || coverUrl!.isEmpty) return placeholder;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: CachedNetworkImage(
        imageUrl: coverUrl!,
        width: width,
        height: height,
        fit: BoxFit.cover,
        placeholder: (_, _) => placeholder,
        errorWidget: (_, _, _) => placeholder,
      ),
    );
  }
}

class _GradientPlaceholder extends StatelessWidget {
  final String seed;
  final double width;
  final double height;
  final double radius;

  const _GradientPlaceholder({
    required this.seed,
    required this.width,
    required this.height,
    required this.radius,
  });

  @override
  Widget build(BuildContext context) {
    final colors = _gradients[seed.hashCode.abs() % _gradients.length];
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Icon(
        Icons.bookmark_rounded,
        color: Colors.white.withValues(alpha: 0.85),
        size: width * 0.34,
      ),
    );
  }
}

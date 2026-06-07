import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Decorative translucent circles behind screen content (design mockup look).
/// Wrap a screen body: `DecoBackground(child: ...)`.
class DecoBackground extends StatelessWidget {
  final Widget child;
  const DecoBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: Stack(
              children: const [
                _Bubble(
                    top: 40,
                    left: -40,
                    size: 150,
                    color: AppColors.lavender,
                    opacity: 0.22),
                _Bubble(
                    top: 120,
                    right: 30,
                    size: 60,
                    color: AppColors.coral,
                    opacity: 0.18),
                _Bubble(
                    bottom: 140,
                    right: -30,
                    size: 130,
                    color: AppColors.mint,
                    opacity: 0.15),
                _Bubble(
                    bottom: 60,
                    left: 30,
                    size: 80,
                    color: AppColors.yellow,
                    opacity: 0.28),
              ],
            ),
          ),
        ),
        child,
      ],
    );
  }
}

class _Bubble extends StatelessWidget {
  final double? top;
  final double? left;
  final double? right;
  final double? bottom;
  final double size;
  final Color color;
  final double opacity;

  const _Bubble({
    this.top,
    this.left,
    this.right,
    this.bottom,
    required this.size,
    required this.color,
    required this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      left: left,
      right: right,
      bottom: bottom,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color.withValues(alpha: opacity),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

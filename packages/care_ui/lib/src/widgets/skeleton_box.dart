import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../tokens/radii.dart';

/// A pulsing placeholder block used while a screen loads.
///
/// Set [animated] to false in tests or screenshots.
class SkeletonBox extends StatelessWidget {
  const SkeletonBox({
    super.key,
    this.width = double.infinity,
    this.height = 16,
    this.radius = const Radius.circular(AppRadii.sm),
    this.animated = true,
  });

  final double width;
  final double height;
  final Radius radius;
  final bool animated;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final box = Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.all(radius),
      ),
    );
    if (!animated) return box;
    return box
        .animate(onPlay: (controller) => controller.repeat(reverse: true))
        .fadeIn(duration: 650.ms, begin: 0.45, curve: Curves.easeInOut);
  }
}

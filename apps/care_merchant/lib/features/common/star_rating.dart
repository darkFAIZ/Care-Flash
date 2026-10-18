import 'package:flutter/material.dart';

/// A 1-5 star rating row used by the care-seeker rating sheet. (FR-CM-24)
class StarRating extends StatelessWidget {
  const StarRating({
    super.key,
    required this.value,
    required this.onChanged,
    this.size = 40,
  });

  final int value;
  final ValueChanged<int> onChanged;
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var star = 1; star <= 5; star++)
          IconButton(
            onPressed: () => onChanged(star),
            iconSize: size,
            icon: Icon(
              star <= value ? Icons.star_rounded : Icons.star_outline_rounded,
              color: star <= value ? Colors.amber : theme.colorScheme.outline,
            ),
          ),
      ],
    );
  }
}

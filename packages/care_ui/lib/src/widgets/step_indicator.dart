import 'package:flutter/material.dart';

import '../tokens/spacing.dart';
import 'app_text.dart';

/// Horizontal step indicator: a dot per step with a short label underneath.
///
/// Use it for short wizards (help type, boundary, schedule, gender).
class StepIndicator extends StatelessWidget {
  const StepIndicator({
    super.key,
    required this.steps,
    required this.current,
    this.completedLabel = 'Done',
    this.currentLabel = 'Now',
  });

  /// Labels in order, for example `['Need', 'Place', 'Filter']`.
  final List<String> steps;

  /// Zero based index of the step the user is on.
  final int current;
  final String completedLabel;
  final String currentLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final clamped = current.clamp(0, steps.length - 1);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < steps.length; i++) ...[
          if (i > 0) const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    if (i > 0)
                      Expanded(
                        child: Container(
                          height: 2,
                          color: i <= clamped ? scheme.primary : scheme.outlineVariant,
                        ),
                      ),
                    _StepDot(
                      index: i,
                      state: i < clamped
                          ? _StepState.done
                          : i == clamped
                              ? _StepState.current
                              : _StepState.upcoming,
                    ),
                    if (i < steps.length - 1)
                      Expanded(
                        child: Container(
                          height: 2,
                          color: i < clamped ? scheme.primary : scheme.outlineVariant,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                AppText(
                  steps[i],
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.labelSmall?.copyWith(
                    color: i <= clamped ? scheme.onSurface : scheme.onSurfaceVariant,
                    fontWeight: i == clamped ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

enum _StepState { done, current, upcoming }

class _StepDot extends StatelessWidget {
  const _StepDot({required this.index, required this.state});

  final int index;
  final _StepState state;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    const double size = 28;
    final Color background = switch (state) {
      _StepState.done => scheme.primary,
      _StepState.current => scheme.primary,
      _StepState.upcoming => scheme.surfaceContainerLow,
    };
    final Color foreground = switch (state) {
      _StepState.done || _StepState.current => scheme.onPrimary,
      _StepState.upcoming => scheme.onSurfaceVariant,
    };

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: background,
        shape: BoxShape.circle,
        border: state == _StepState.upcoming
            ? Border.all(color: scheme.outlineVariant)
            : null,
      ),
      child: Center(
        child: state == _StepState.done
            ? Icon(Icons.check_rounded, size: 17, color: foreground)
            : AppText(
                '${index + 1}',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: foreground,
                  fontWeight: FontWeight.w700,
                ),
              ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../theme/semantic_colors.dart';
import 'app_text.dart';

/// Which colour family a [StatusChip] uses.
enum AppStatusTint { neutral, info, success, warning, danger }

/// A small pill used for booking and account states.
class StatusChip extends StatelessWidget {
  const StatusChip({
    super.key,
    required this.label,
    this.tint = AppStatusTint.neutral,
    this.icon,
  });

  final String label;
  final AppStatusTint tint;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final semantics = AppSemanticColors.of(context);
    final (Color container, Color foreground) = switch (tint) {
      AppStatusTint.neutral => (scheme.surfaceContainerHighest, scheme.onSurfaceVariant),
      AppStatusTint.info => (scheme.primaryContainer, scheme.onPrimaryContainer),
      AppStatusTint.success => (semantics.successContainer, semantics.onSuccessContainer),
      AppStatusTint.warning => (semantics.warningContainer, semantics.onWarningContainer),
      AppStatusTint.danger => (semantics.dangerContainer, semantics.onDangerContainer),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: container,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 15, color: foreground), const SizedBox(width: 5)],
          AppText(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

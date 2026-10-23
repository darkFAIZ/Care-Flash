import 'package:flutter/material.dart';

import '../theme/semantic_colors.dart';
import 'app_text.dart';

/// Visual weight of an [AppButton].
///
/// `danger` is reserved for the Report action so it always reads differently
/// from the ordinary End Early button. (AGENTS.md §5)
enum AppButtonVariant { primary, secondary, ghost, danger }

/// The one button used across both apps: min height 52, full width by default.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.loading = false,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final IconData? icon;
  final bool loading;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final semantics = AppSemanticColors.of(context);
    final disabled = onPressed == null && !loading;
    // While loading the button keeps its enabled colours so the state change
    // does not make the screen flash grey.
    final VoidCallback? pressed = loading
        ? () {}
        : (disabled ? null : onPressed);

    final Color spinnerColor = switch (variant) {
      AppButtonVariant.primary || AppButtonVariant.danger => scheme.onPrimary,
      AppButtonVariant.secondary => scheme.primary,
      AppButtonVariant.ghost => scheme.primary,
    };

    final Widget child = loading
        ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: spinnerColor),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[Icon(icon, size: 20), const SizedBox(width: 8)],
              Flexible(child: AppText(label, overflow: TextOverflow.ellipsis)),
            ],
          );

    final Widget button = switch (variant) {
      AppButtonVariant.primary => FilledButton(onPressed: pressed, child: child),
      AppButtonVariant.secondary => OutlinedButton(onPressed: pressed, child: child),
      AppButtonVariant.ghost => TextButton(onPressed: pressed, child: child),
      AppButtonVariant.danger => FilledButton(
          onPressed: pressed,
          style: FilledButton.styleFrom(
            backgroundColor: semantics.danger,
            foregroundColor: AppSemanticColors.onSolid,
          ),
          child: child,
        ),
    };

    if (!expand) return button;
    return SizedBox(width: double.infinity, child: button);
  }
}

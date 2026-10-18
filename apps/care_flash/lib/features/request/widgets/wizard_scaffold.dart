import 'package:flutter/material.dart';

/// Shared scaffold for the request-flow steps: a progress bar, the step body
/// and a single primary action pinned to the bottom. (AGENTS.md §8)
class WizardScaffold extends StatelessWidget {
  const WizardScaffold({
    super.key,
    required this.title,
    required this.step,
    required this.totalSteps,
    required this.child,
    required this.primaryLabel,
    this.onPrimary,
    this.primaryEnabled = true,
    this.footer,
  });

  final String title;
  final int step;
  final int totalSteps;
  final Widget child;
  final String primaryLabel;
  final VoidCallback? onPrimary;
  final bool primaryEnabled;

  /// Optional content shown above the primary button, for example a summary.
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Step $step of $totalSteps',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: step / totalSteps,
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: child,
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (footer != null) ...[footer!, const SizedBox(height: 12)],
              FilledButton(
                onPressed: primaryEnabled ? onPrimary : null,
                child: Text(primaryLabel),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

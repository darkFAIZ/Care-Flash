import 'package:care_ui/care_ui.dart';
import 'package:flutter/material.dart';

/// Shared scaffold for the request-flow steps: a step indicator, the step body
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

  static const List<String> defaultStepLabels = <String>[
    'Need',
    'Boundaries',
    'Schedule',
    'Preference',
  ];

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
    final labels = totalSteps == defaultStepLabels.length
        ? defaultStepLabels
        : List<String>.generate(totalSteps, (i) => '${i + 1}');

    return Scaffold(
      appBar: AppBar(title: AppText(title)),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.pageGutter,
              AppSpacing.lg,
              AppSpacing.pageGutter,
              0,
            ),
            child: StepIndicator(steps: labels, current: step - 1),
          ),
          Expanded(
            child: SingleChildScrollView(padding: AppSpacing.page, child: child),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.pageGutter,
            AppSpacing.sm,
            AppSpacing.pageGutter,
            AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (footer != null) ...[footer!, const SizedBox(height: AppSpacing.md)],
              AppButton(
                label: primaryLabel,
                onPressed: primaryEnabled ? onPrimary : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

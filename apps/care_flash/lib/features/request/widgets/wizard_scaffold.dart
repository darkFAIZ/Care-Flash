import 'package:care_ui/care_ui.dart';
import 'package:flutter/material.dart';

import '../../../core/theme.dart';

/// Shared scaffold for the request-flow steps matching Stitch start_care_request_1_4.
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
    this.showReassurance = true,
  });

  static const List<String> defaultStepLabels = <String>[
    '1. Care Type',
    '2. Boundaries',
    '3. Schedule',
    '4. Cost Est.',
  ];

  final String title;
  final int step;
  final int totalSteps;
  final Widget child;
  final String primaryLabel;
  final VoidCallback? onPrimary;
  final bool primaryEnabled;
  final Widget? footer;
  final bool showReassurance;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final labels = totalSteps == defaultStepLabels.length
        ? defaultStepLabels
        : List<String>.generate(totalSteps, (i) => '${i + 1}');

    return Scaffold(
      backgroundColor: WarmEmpathyColors.surface,
      appBar: AppBar(
        titleSpacing: AppSpacing.pageGutter,
        title: Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: WarmEmpathyColors.onSurface,
          ),
        ),
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top Multi-Segment Visual Stepper Tracker
          Container(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.pageGutter,
              AppSpacing.sm,
              AppSpacing.pageGutter,
              AppSpacing.md,
            ),
            decoration: BoxDecoration(
              color: WarmEmpathyColors.surfaceContainerLowest,
              boxShadow: const [
                BoxShadow(
                  color: Color(0x06000000),
                  offset: Offset(0, 1),
                  blurRadius: 4,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: const BoxDecoration(
                            color: WarmEmpathyColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '$step',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          labels[step - 1],
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: WarmEmpathyColors.primary,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'Step $step of $totalSteps',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: WarmEmpathyColors.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),

                // Multi-Segment Visual Progress Bar
                Row(
                  children: [
                    for (int i = 0; i < totalSteps; i++) ...[
                      if (i > 0) const SizedBox(width: 6),
                      Expanded(
                        child: Container(
                          height: 6,
                          decoration: BoxDecoration(
                            color: i < step
                                ? WarmEmpathyColors.primary
                                : WarmEmpathyColors.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(9999),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 6),

                // Stepper Labels Micro-Row
                Row(
                  children: [
                    for (int i = 0; i < totalSteps; i++) ...[
                      if (i > 0) const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          labels[i],
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: i < step
                                ? WarmEmpathyColors.primary
                                : WarmEmpathyColors.onSurfaceVariant,
                            fontWeight: i == step - 1
                                ? FontWeight.bold
                                : FontWeight.normal,
                            fontSize: 10.5,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // Scrollable Step Body
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.pageGutter,
                vertical: AppSpacing.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Reassurance Banner
                  if (showReassurance) ...[
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: WarmEmpathyColors.secondaryContainer.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: WarmEmpathyColors.secondary.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.health_and_safety_rounded,
                              color: WarmEmpathyColors.secondary,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '100% Background-Checked Caregivers',
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: WarmEmpathyColors.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Every visit is insured, verified, and backed by 24/7 care support.',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: WarmEmpathyColors.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                  child,
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.pageGutter,
            AppSpacing.sm,
            AppSpacing.pageGutter,
            AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: WarmEmpathyColors.surfaceContainerLowest,
            border: const Border(
              top: BorderSide(color: WarmEmpathyColors.cardBorder),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (footer != null) ...[footer!, const SizedBox(height: AppSpacing.sm)],
              SizedBox(
                height: 50,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: WarmEmpathyColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: primaryEnabled ? onPrimary : null,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        primaryLabel,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.arrow_forward_rounded, size: 18),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              // Trust Assurance Footer
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.verified_user_rounded,
                    color: WarmEmpathyColors.secondary,
                    size: 15,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'Safe & Encrypted • Zero penalty cancellation within 10 mins',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: WarmEmpathyColors.onSurfaceVariant,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

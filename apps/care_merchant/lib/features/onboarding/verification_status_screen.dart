import 'package:care_core/care_core.dart';
import 'package:care_ui/care_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../home/home_shell.dart';
import 'onboarding_screen.dart';
import 'safety_module_screen.dart';

/// Shows the platform's identity review state, explains any rejection and
/// offers a resubmission path. (FR-CM-3)
class VerificationStatusScreen extends ConsumerWidget {
  const VerificationStatusScreen({super.key});

  static const String route = '/verification-status';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final caregiver = ref.watch(caregiverStateProvider).value;

    if (caregiver == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final status = caregiver.verificationStatus;
    final (icon, color) = switch (status) {
      VerificationStatus.pending => (Icons.hourglass_top_rounded, theme.colorScheme.primary),
      VerificationStatus.approved => (Icons.verified_outlined, theme.colorScheme.primary),
      VerificationStatus.rejected => (Icons.error_outline, theme.colorScheme.error),
      VerificationStatus.notSubmitted => (Icons.info_outline, theme.colorScheme.onSurfaceVariant),
    };

    final message = switch (status) {
      VerificationStatus.pending =>
        'Your KTP is being reviewed. This usually takes a short while. '
            'You will be able to receive requests once you are verified.',
      VerificationStatus.approved =>
        'You are verified. You can now complete the safety module and start '
            'receiving requests.',
      VerificationStatus.rejected =>
        caregiver.rejectionReason ?? 'Your submission was not accepted.',
      VerificationStatus.notSubmitted =>
        'You have not submitted your KTP yet.',
    };

    return Scaffold(
      appBar: AppBar(title: const AppText('Verification status')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: AppSpacing.page,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(icon, size: 64, color: color),
                  const SizedBox(height: AppSpacing.lg),
                  AppText(
                    status.label,
                    style: theme.textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppText(
                    message,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: status == VerificationStatus.rejected
                          ? AppSemanticColors.of(context).danger
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (caregiver.ktpNumber != null) ...[
                    const SizedBox(height: AppSpacing.lg),
                    AppCard(
                      padding: EdgeInsets.zero,
                      child: ListTile(
                        leading: const Icon(Icons.badge_outlined),
                        title: AppText('KTP ${_maskedKtp(caregiver.ktpNumber!)}'),
                        subtitle: const AppText(
                          'Only the platform can see your full KTP number.',
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.xl),
                  if (status == VerificationStatus.approved) ...[
                    AppButton(
                      label: caregiver.safetyModuleCompleted
                          ? 'Continue to requests'
                          : 'Continue to the safety module',
                      onPressed: caregiver.safetyModuleCompleted
                          ? () => context.go(HomeShell.route)
                          : () => context.go(SafetyModuleScreen.route),
                    ),
                  ] else if (status == VerificationStatus.rejected ||
                      status == VerificationStatus.notSubmitted) ...[
                    AppButton(
                      label: 'Resubmit your KTP',
                      onPressed: () => context.go(OnboardingScreen.route),
                    ),
                  ] else if (status == VerificationStatus.pending) ...[
                    // The review completes on its own; watch the caregiver so
                    // this screen updates when it is approved.
                    const SizedBox(height: AppSpacing.sm),
                    AppText(
                      'Waiting for review…',
                      style: theme.textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Shows only the last four digits, e.g. `•••• •••• •••• 1234`.
String _maskedKtp(String ktp) {
  final digits = ktp.trim();
  if (digits.length <= 4) {
    return digits;
  }
  return '•••• •••• •••• ${digits.substring(digits.length - 4)}';
}

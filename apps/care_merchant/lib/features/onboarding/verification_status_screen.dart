import 'package:care_core/care_core.dart';
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
      VerificationStatus.pending => (Icons.hourglass_top, theme.colorScheme.primary),
      VerificationStatus.approved => (Icons.verified_outlined, theme.colorScheme.primary),
      VerificationStatus.rejected => (Icons.error_outline, theme.colorScheme.error),
      VerificationStatus.notSubmitted => (Icons.info_outline, theme.colorScheme.onSurfaceVariant),
    };

    final message = switch (status) {
      VerificationStatus.pending =>
        'Your student ID is being reviewed. This usually takes a short while. '
            'You will be able to receive requests once you are verified.',
      VerificationStatus.approved =>
        'You are verified. You can now complete the safety module and start '
            'receiving requests.',
      VerificationStatus.rejected =>
        caregiver.rejectionReason ?? 'Your submission was not accepted.',
      VerificationStatus.notSubmitted =>
        'You have not submitted your student ID yet.',
    };

    return Scaffold(
      appBar: AppBar(title: const Text('Verification status')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(icon, size: 64, color: color),
                  const SizedBox(height: 16),
                  Text(
                    status.label,
                    style: theme.textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    message,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: status == VerificationStatus.rejected
                          ? theme.colorScheme.error
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (caregiver.university != null) ...[
                    const SizedBox(height: 24),
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.school_outlined),
                        title: Text(caregiver.university!),
                        subtitle: caregiver.studentIdNumber == null
                            ? null
                            : Text('Student ID ${caregiver.studentIdNumber}'),
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),
                  if (status == VerificationStatus.approved) ...[
                    FilledButton(
                      onPressed: caregiver.safetyModuleCompleted
                          ? () => context.go(HomeShell.route)
                          : () => context.go(SafetyModuleScreen.route),
                      child: Text(
                        caregiver.safetyModuleCompleted
                            ? 'Continue to requests'
                            : 'Continue to the safety module',
                      ),
                    ),
                  ] else if (status == VerificationStatus.rejected ||
                      status == VerificationStatus.notSubmitted) ...[
                    FilledButton(
                      onPressed: () => context.go(OnboardingScreen.route),
                      child: const Text('Resubmit your student ID'),
                    ),
                  ] else if (status == VerificationStatus.pending) ...[
                    // The review completes on its own; watch the caregiver so
                    // this screen updates when it is approved.
                    const SizedBox(height: 8),
                    Text(
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

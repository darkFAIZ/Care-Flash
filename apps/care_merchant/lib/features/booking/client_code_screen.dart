import 'package:care_core/care_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import 'button_handover_screen.dart';

/// Shows the caregiver's one-time identity code for the care seeker to confirm.
class ClientCodeScreen extends ConsumerWidget {
  const ClientCodeScreen({super.key});

  static const String route = '/booking/client-code';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    ref.listen(activeBookingProvider, (previous, next) {
      if (next.value?.status == BookingStatus.codeVerified) {
        context.pushReplacement(ButtonHandoverScreen.route);
      }
    });
    final code = ref.watch(activeBookingProvider).value?.clientCode;
    return Scaffold(
      appBar: AppBar(title: const Text('Verify your identity')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(
                Icons.verified_user_outlined,
                size: 56,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 20),
              Text(
                'Share this code with the care seeker',
                style: theme.textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'They will enter it in Care-Flash to confirm you are their assigned caregiver.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Center(
                  child: Text(
                    code ?? '------',
                    style: theme.textTheme.displaySmall?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 10,
                    ),
                  ),
                ),
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.hourglass_top_rounded),
                label: const Text('Waiting for confirmation'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

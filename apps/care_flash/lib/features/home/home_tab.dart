import 'package:care_core/care_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../payment_info/payment_info_screen.dart';
import '../request/confirmed_screen.dart';
import '../request/help_request_screen.dart';
import '../request/matched_caregiver_screen.dart';
import '../request/matching_screen.dart';
import '../request/request_draft.dart';
import '../support/help_support_screen.dart';

/// The screen the ongoing-activity card should open for [booking]. (FR-CS-21)
String _ongoingRoute(Booking booking) {
  if (booking.status.isSessionStarted) {
    return '/session';
  }
  return switch (booking.status) {
    BookingStatus.matching || BookingStatus.noMatch => MatchingScreen.route,
    BookingStatus.matched => MatchedCaregiverScreen.route,
    _ => ConfirmedScreen.route,
  };
}

/// Home page: greeting, the Need Help action and the ongoing activity card.
class HomeTab extends ConsumerWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final user = ref.watch(authStateProvider).value;
    final booking = ref.watch(activeBookingProvider).value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Care-Flash'),
        actions: [
          IconButton(
            tooltip: 'Help and support',
            onPressed: () => context.push(HelpSupportScreen.route),
            icon: const Icon(Icons.support_agent),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Hi, ${user?.name.split(' ').first ?? 'there'}',
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: 4),
          Text(
            'How can we help you today?',
            style: theme.textTheme.bodyLarge
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 20),
          _NeedHelpCard(
            onTap: () {
              if (booking != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('You already have an ongoing request.'),
                  ),
                );
                context.push(_ongoingRoute(booking));
                return;
              }
              ref.read(requestDraftProvider.notifier).reset();
              context.push(HelpRequestScreen.route);
            },
          ),
          if (booking != null) ...[
            const SizedBox(height: 16),
            _OngoingActivityCard(booking: booking),
          ],
          const SizedBox(height: 24),
          Text('Quick actions', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _QuickAction(
                  icon: Icons.credit_card,
                  label: 'Payment info',
                  onTap: () => context.push(PaymentInfoScreen.route),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _QuickAction(
                  icon: Icons.support_agent,
                  label: 'Help & support',
                  onTap: () => context.push(HelpSupportScreen.route),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NeedHelpCard extends StatelessWidget {
  const _NeedHelpCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.volunteer_activism_outlined,
              size: 36,
              color: theme.colorScheme.onPrimaryContainer,
            ),
            const SizedBox(height: 12),
            Text(
              'Need help?',
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Request a nearby verified caregiver for a short visit.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onTap,
              icon: const Icon(Icons.add),
              label: const Text('Start a request'),
            ),
          ],
        ),
      ),
    );
  }
}

class _OngoingActivityCard extends StatelessWidget {
  const _OngoingActivityCard({required this.booking});

  final Booking booking;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final caregiver = booking.caregiver;
    final target = _ongoingRoute(booking);
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.secondaryContainer,
          child: Icon(
            booking.status.isSessionStarted
                ? Icons.directions_run
                : Icons.schedule,
            color: theme.colorScheme.onSecondaryContainer,
          ),
        ),
        title: Text('Ongoing: ${booking.status.label}'),
        subtitle: Text(
          caregiver == null
              ? 'Ref ${booking.requestReference}'
              : '${caregiver.name} · Ref ${booking.requestReference}',
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.push(target),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
          child: Column(
            children: [
              Icon(icon),
              const SizedBox(height: 8),
              Text(label, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}

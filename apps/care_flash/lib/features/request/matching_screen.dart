import 'package:care_core/care_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../demo/demo_controls_sheet.dart';
import '../home/home_shell.dart';
import 'matched_caregiver_screen.dart';

/// Matching status after the request is submitted. Also shows the no-match
/// fallback with a filter retry, since it is the matching step that fails.
/// (FR-CS-9)
class MatchingScreen extends ConsumerStatefulWidget {
  const MatchingScreen({super.key});

  static const String route = '/matching';

  @override
  ConsumerState<MatchingScreen> createState() => _MatchingScreenState();
}

class _MatchingScreenState extends ConsumerState<MatchingScreen> {
  GenderFilter? _retryFilter;

  Future<void> _cancel() async {
    await ref
        .read(platformProvider)
        .cancelBooking(CancellationReason.userCancelled);
    if (mounted) {
      context.go(HomeShell.route);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(activeBookingProvider, (previous, next) {
      final booking = next.value;
      if (booking == null) {
        return;
      }
      if (booking.status == BookingStatus.matched) {
        context.go(MatchedCaregiverScreen.route);
      } else if (!booking.status.isOpen) {
        context.go(HomeShell.route);
      }
    });

    final theme = Theme.of(context);
    final booking = ref.watch(activeBookingProvider).value;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Finding a caregiver'),
        actions: [
          if (kDebugMode)
            IconButton(
              tooltip: 'Demo controls',
              icon: const Icon(Icons.bug_report_outlined),
              onPressed: () => showDemoControls(context),
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: booking == null
            ? _message(
                theme,
                Icons.info_outline,
                'No active request',
                'There is nothing to match right now.',
              )
            : booking.status == BookingStatus.noMatch
                ? _noMatch(theme, booking)
                : _searching(theme, booking),
      ),
    );
  }

  Widget _searching(ThemeData theme, Booking booking) {
    final matched = booking.status == BookingStatus.matched;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 24),
          Text(
            matched ? 'Caregiver found' : 'Looking for a nearby caregiver…',
            style: theme.textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'This usually takes under a minute. Please keep the app open.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          OutlinedButton(
            onPressed: _cancel,
            child: const Text('Cancel request'),
          ),
        ],
      ),
    );
  }

  Widget _noMatch(ThemeData theme, Booking booking) {
    final selected = _retryFilter ?? booking.genderFilter;
    return ListView(
      children: [
        Icon(Icons.search_off, size: 64, color: theme.colorScheme.error),
        const SizedBox(height: 16),
        Text(
          'No caregiver found',
          style: theme.textTheme.titleLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'No caregiver matches the current preference right now. Try a '
          'different gender preference, or cancel the request.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        Text('Caregiver preference', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        for (final filter in GenderFilter.values) ...[
          Card(
            color: selected == filter
                ? theme.colorScheme.secondaryContainer
                : null,
            child: ListTile(
              leading: Icon(
                selected == filter ? Icons.check_circle : Icons.person_outline,
                color: selected == filter ? theme.colorScheme.primary : null,
              ),
              title: Text(filter.label),
              onTap: () => setState(() => _retryFilter = filter),
            ),
          ),
          const SizedBox(height: 8),
        ],
        const SizedBox(height: 8),
        FilledButton(
          onPressed: () =>
              ref.read(platformProvider).retryWithGenderFilter(selected),
          child: const Text('Try again'),
        ),
        const SizedBox(height: 8),
        TextButton(onPressed: _cancel, child: const Text('Cancel request')),
      ],
    );
  }

  Widget _message(
    ThemeData theme,
    IconData icon,
    String title,
    String body,
  ) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 56, color: theme.colorScheme.primary),
          const SizedBox(height: 16),
          Text(title, style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            body,
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => context.go(HomeShell.route),
            child: const Text('Back home'),
          ),
        ],
      ),
    );
  }
}

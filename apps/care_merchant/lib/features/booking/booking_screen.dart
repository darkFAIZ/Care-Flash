import 'package:care_core/care_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/date_time_format.dart';
import '../../core/providers.dart';
import '../common/boundary_checklist_card.dart';
import '../demo/demo_controls_sheet.dart';
import '../home/home_shell.dart';
import '../session/session_screen.dart';
import 'button_handover_screen.dart';
import 'client_code_screen.dart';

/// The accepted booking hub: trip to the care seeker, arrival, client-code
/// verification and the safety-button handover. (FR-CM-10 to FR-CM-16)
///
/// Each status shows the next step and a single primary action, so the caregiver
/// moves through the pre-session flow one tap at a time.
class BookingScreen extends ConsumerStatefulWidget {
  const BookingScreen({super.key});

  static const String route = '/booking';

  @override
  ConsumerState<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends ConsumerState<BookingScreen> {
  bool _busy = false;

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    await action();
    if (!mounted) {
      return;
    }
    setState(() => _busy = false);
  }

  Future<void> _reportDanger() async {
    final controller = TextEditingController();
    final submitted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Report a safety concern'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'If you feel unsafe before the session, tell us what is '
              'happening. The booking will be cancelled and support notified.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              maxLines: 3,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(hintText: 'Describe the concern'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Send report'),
          ),
        ],
      ),
    );
    if (submitted != true) {
      return;
    }
    final description = controller.text.trim();
    if (!mounted) {
      return;
    }
    await _run(
      () => ref.read(platformProvider).reportDanger(
            description.isEmpty ? 'Safety concern reported.' : description,
          ),
    );
    if (!mounted) {
      return;
    }
    context.go(HomeShell.route);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final booking = ref.watch(activeBookingProvider).value;

    if (booking == null) {
      return Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text('Booking'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: 56,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 16),
                const Text(
                  'This booking is closed.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () => context.go(HomeShell.route),
                  child: const Text('Back home'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(booking.status.label),
        actions: [
          if (kDebugMode)
            IconButton(
              tooltip: 'Demo controls',
              icon: const Icon(Icons.bug_report_outlined),
              onPressed: () => showDemoControls(context),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (kDebugMode && booking.clientCode != null)
                    _ClientCodeDebug(clientCode: booking.clientCode!),
                  _TripCard(booking: booking),
                  const SizedBox(height: 16),
                  _BookingDetailsCard(booking: booking),
                  const SizedBox(height: 16),
                  BoundaryChecklistCard(checklist: booking.checklist),
                ],
              ),
            ),
            _actions(theme, booking),
          ],
        ),
      ),
    );
  }

  Widget _actions(ThemeData theme, Booking booking) {
    final (label, onPressed) = _primaryAction(booking);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_canReportDanger(booking))
            OutlinedButton.icon(
              onPressed: _busy ? null : _reportDanger,
              icon: const Icon(Icons.report_problem_outlined),
              label: const Text('Report a safety concern'),
            ),
          if (_canReportDanger(booking)) const SizedBox(height: 8),
          FilledButton(
            onPressed: _busy ? null : onPressed,
            child: _busy
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(label),
          ),
        ],
      ),
    );
  }

  bool _canReportDanger(Booking booking) => switch (booking.status) {
        BookingStatus.confirmed ||
        BookingStatus.caregiverTravelling ||
        BookingStatus.arrived ||
        BookingStatus.codeVerified =>
          true,
        _ => false,
      };

  (String, VoidCallback) _primaryAction(Booking booking) {
    return switch (booking.status) {
      BookingStatus.confirmed => (
          'I\'m on my way',
          () => _run(ref.read(platformProvider).startTrip),
        ),
      BookingStatus.caregiverTravelling => (
          'I\'ve arrived',
          () => _run(ref.read(platformProvider).markArrived),
        ),
      BookingStatus.arrived => (
          'Verify the client code',
          () => context.push(ClientCodeScreen.route),
        ),
      BookingStatus.codeVerified => (
          'Safety button handover',
          () => context.push(ButtonHandoverScreen.route),
        ),
      BookingStatus.active => (
          'Open session',
          () => context.push(SessionScreen.route),
        ),
      _ => ('Back home', () => context.go(HomeShell.route)),
    };
  }
}

class _ClientCodeDebug extends StatelessWidget {
  const _ClientCodeDebug({required this.clientCode});

  final String clientCode;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Debug only: the real care seeker shows this on their own device.
    return Card(
      color: theme.colorScheme.tertiaryContainer,
      child: ListTile(
        leading: const Icon(Icons.bug_report_outlined),
        title: const Text('Demo: the care seeker\'s client code'),
        trailing: Text(
          clientCode,
          style: theme.textTheme.titleMedium,
        ),
      ),
    );
  }
}

/// The trip to the care seeker: pickup, destination and the mock Grab status.
/// (FR-CM-10)
class _TripCard extends StatelessWidget {
  const _TripCard({required this.booking});

  final Booking booking;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (status, icon) = switch (booking.status) {
      BookingStatus.confirmed => (
          'Book a Grab ride to the care seeker.',
          Icons.local_taxi_outlined,
        ),
      BookingStatus.caregiverTravelling => (
          'On the way. Share your trip with the platform.',
          Icons.directions_car_filled_outlined,
        ),
      BookingStatus.arrived || BookingStatus.codeVerified => (
          'You have arrived at the care seeker.',
          Icons.location_on_outlined,
        ),
      _ => ('Trip details.', Icons.route_outlined),
    };

    return Card(
      child: Column(
        children: [
          ListTile(
            leading: Icon(icon, color: theme.colorScheme.primary),
            title: Text(status),
            // TODO(team): no real Grab integration in the prototype; the
            // care seeker's mock ride supplies pickup tracking later. (FR-CM-10)
            subtitle: const Text('Grab integration is mocked for the demo.'),
          ),
          const Divider(height: 0),
          ListTile(
            leading: const Icon(Icons.my_location_outlined),
            title: const Text('Pickup'),
            subtitle: const Text('Your current location'),
          ),
          ListTile(
            leading: const Icon(Icons.location_on_outlined),
            title: const Text('Destination'),
            subtitle: Text(
              '${booking.location.label}\n${booking.location.address}',
            ),
            isThreeLine: true,
          ),
        ],
      ),
    );
  }
}

class _BookingDetailsCard extends StatelessWidget {
  const _BookingDetailsCard({required this.booking});

  final Booking booking;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final price = booking.price;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    booking.helpType.label,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                Text(booking.requestReference,
                    style: theme.textTheme.labelLarge),
              ],
            ),
            if (booking.description != null) ...[
              const SizedBox(height: 8),
              Text(booking.description!, style: theme.textTheme.bodyMedium),
            ],
            const SizedBox(height: 12),
            _meta(theme, Icons.schedule, booking.duration.label),
            _meta(theme, Icons.event, formatVisitTime(booking.scheduledAt)),
            if (price != null)
              _meta(
                theme,
                Icons.payments_outlined,
                '${formatIdr(price.caregiverPrice)} to you',
              ),
          ],
        ),
      ),
    );
  }

  Widget _meta(ThemeData theme, IconData icon, String label) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: 8),
            Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
          ],
        ),
      );
}

import 'package:care_core/care_core.dart';
import 'package:care_ui/care_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../common/qr_placeholder.dart';
import '../demo/demo_controls_sheet.dart';
import '../home/home_shell.dart';
import '../session/session_screen.dart';

/// Presents the booking-linked safety button to the care seeker. (FR-CM-15,
/// FR-CM-16)
///
/// The caregiver shows the QR code or taps an NFC tag; the care seeker's device
/// performs the read. The prototype has no encoder or NFC writer, so this screen
/// shows the button identifier and waits for the mock platform to confirm the
/// care seeker's scan, then opens the session.
class ButtonHandoverScreen extends ConsumerStatefulWidget {
  const ButtonHandoverScreen({super.key});

  static const String route = '/booking/handover';

  @override
  ConsumerState<ButtonHandoverScreen> createState() =>
      _ButtonHandoverScreenState();
}

class _ButtonHandoverScreenState extends ConsumerState<ButtonHandoverScreen> {
  ButtonVerificationMethod _method = ButtonVerificationMethod.qr;
  bool _navigated = false;

  void _goToSession() {
    if (_navigated) {
      return;
    }
    _navigated = true;
    context.go(SessionScreen.route);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final booking = ref.watch(activeBookingProvider).value;

    // The mock confirms the scan, or the demo controls do it by hand.
    ref.listen(activeBookingProvider, (previous, next) {
      if (next.value?.status == BookingStatus.active) {
        _goToSession();
      }
    });

    if (booking != null && booking.status == BookingStatus.active) {
      // The scan may already have been confirmed before this screen built.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _goToSession();
        }
      });
    }

    if (booking == null) {
      return Scaffold(
        appBar: AppBar(title: const AppText('Safety button')),
        body: EmptyState(
          title: 'The safety button was not verified.',
          actionLabel: 'Back home',
          onAction: () => context.go(HomeShell.route),
        ),
      );
    }

    final alreadyVerified = booking.status == BookingStatus.active;

    return Scaffold(
      appBar: AppBar(
        title: const AppText('Safety button'),
        actions: [
          if (kDebugMode)
            IconButton(
              tooltip: trText(context, 'Demo controls'),
              icon: const Icon(Icons.bug_report_outlined),
              onPressed: () => showDemoControls(context),
            ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: AppSpacing.page,
          children: [
            AppText(
              'Hand the safety button to the care seeker',
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            AppText(
              _method == ButtonVerificationMethod.qr
                  ? 'Ask the care seeker to scan this QR code with Care-Flash.'
                  : 'Ask the care seeker to read the button with their phone '
                      '(NFC).',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            Center(
              child: _method == ButtonVerificationMethod.qr
                  ? QrPlaceholder(value: booking.safetyButtonId ?? booking.id)
                  : const Icon(
                      Icons.contactless_outlined,
                      size: 120,
                    ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Center(
              child: AppText(
                booking.safetyButtonId ?? booking.id,
                style: theme.textTheme.labelLarge,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            SegmentedButton<ButtonVerificationMethod>(
              segments: const [
                ButtonSegment(
                  value: ButtonVerificationMethod.qr,
                  label: AppText('QR code'),
                  icon: Icon(Icons.qr_code_2_outlined),
                ),
                ButtonSegment(
                  value: ButtonVerificationMethod.nfc,
                  label: AppText('NFC'),
                  icon: Icon(Icons.contactless_outlined),
                ),
              ],
              selected: {_method},
              onSelectionChanged: (selection) =>
                  setState(() => _method = selection.first),
            ),
            const SizedBox(height: AppSpacing.xl),
            // The caregiver never confirms the button. Only the care seeker's
            // scan, checked by the platform, starts the session. (FR-P-18)
            if (alreadyVerified)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_rounded,
                      color: theme.colorScheme.primary),
                  const SizedBox(width: AppSpacing.sm),
                  AppText(
                    'Verified by the care seeker',
                    style: theme.textTheme.titleSmall,
                  ),
                ],
              )
            else
              Row(
                children: [
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: AppText(
                      'Waiting for the care seeker to verify…',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

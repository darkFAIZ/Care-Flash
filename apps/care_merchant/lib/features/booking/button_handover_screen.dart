import 'dart:convert';
import 'package:care_core/care_core.dart';
import 'package:care_ui/care_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager/ndef_record.dart';
import 'package:nfc_manager_ndef/nfc_manager_ndef.dart';

import '../../core/providers.dart';
import '../common/qr_placeholder.dart';
import '../demo/demo_controls_sheet.dart';
import '../home/home_shell.dart';
import '../session/session_screen.dart';

/// Presents the booking-linked safety button to the care seeker. (FR-CM-15,
/// FR-CM-16)
///
/// The caregiver shows a booking-bound QR code or writes the same token to an
/// NFC tag. Care-Flash reads and verifies the token through the shared backend.
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
  bool _writingNfc = false;
  String? _nfcMessage;

  Future<void> _writeNfcTag(String payload) async {
    if (kIsWeb) {
      setState(
        () => _nfcMessage = 'NFC writing needs the installed mobile app.',
      );
      return;
    }
    final availability = await NfcManager.instance.checkAvailability();
    if (!mounted) return;
    if (availability != NfcAvailability.enabled) {
      setState(
        () => _nfcMessage = availability == NfcAvailability.disabled
            ? 'Turn on NFC in your phone settings, then try again.'
            : 'This phone does not support NFC. Use the QR code instead.',
      );
      return;
    }
    setState(() {
      _writingNfc = true;
      _nfcMessage = 'Hold a writable NDEF tag near the top of this phone.';
    });
    final text = utf8.encode(payload);
    final message = NdefMessage(
      records: [
        NdefRecord(
          typeNameFormat: TypeNameFormat.wellKnown,
          type: Uint8List.fromList([0x54]), // Text record
          identifier: Uint8List(0),
          payload: Uint8List.fromList([2, 0x65, 0x6e, ...text]), // en
        ),
      ],
    );
    try {
      await NfcManager.instance.startSession(
        pollingOptions: const {NfcPollingOption.iso14443},
        alertMessageIos: 'Hold a writable NFC tag near the phone.',
        onDiscovered: (tag) async {
          try {
            final ndef = Ndef.from(tag);
            if (ndef == null ||
                !ndef.isWritable ||
                message.byteLength > ndef.maxSize) {
              throw StateError('Use a writable, NDEF-formatted NFC tag.');
            }
            await ndef.write(message: message);
            await NfcManager.instance.stopSession(
              alertMessageIos: 'Safety button code written.',
            );
            if (mounted) {
              setState(() {
                _writingNfc = false;
                _nfcMessage = 'NFC tag ready. The care seeker can scan it now.';
              });
            }
          } catch (error) {
            await NfcManager.instance.stopSession(errorMessageIos: '$error');
            if (mounted) {
              setState(() {
                _writingNfc = false;
                _nfcMessage = 'Could not write this NFC tag: $error';
              });
            }
          }
        },
      );
    } catch (error) {
      if (mounted) {
        setState(() {
          _writingNfc = false;
          _nfcMessage = 'Could not start NFC writing: $error';
        });
      }
    }
  }

  @override
  void dispose() {
    if (_writingNfc && !kIsWeb) NfcManager.instance.stopSession();
    super.dispose();
  }

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
                  ? booking.safetyButtonId == null
                        ? _MissingButtonCode(status: booking.status)
                        : QrPlaceholder(value: booking.safetyButtonId!)
                  : const Icon(Icons.contactless_outlined, size: 120),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (booking.safetyButtonId != null)
              Center(
                child: AppText(
                  booking.safetyButtonId!,
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
                  Icon(
                    Icons.check_circle_rounded,
                    color: theme.colorScheme.primary,
                  ),
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
            if (_method == ButtonVerificationMethod.nfc &&
                !alreadyVerified) ...[
              const SizedBox(height: AppSpacing.md),
              AppButton(
                label: _writingNfc
                    ? 'Waiting for NFC tag…'
                    : 'Write safety code to NFC tag',
                icon: Icons.nfc_rounded,
                loading: _writingNfc,
                onPressed: _writingNfc || booking.safetyButtonId == null
                    ? null
                    : () => _writeNfcTag(booking.safetyButtonId!),
              ),
              if (_nfcMessage != null) ...[
                const SizedBox(height: AppSpacing.sm),
                AppText(
                  _nfcMessage!,
                  style: theme.textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _MissingButtonCode extends StatelessWidget {
  const _MissingButtonCode({required this.status});

  final BookingStatus status;

  @override
  Widget build(BuildContext context) {
    final codeStageReached =
        status == BookingStatus.codeVerified ||
        status == BookingStatus.buttonVerified ||
        status == BookingStatus.active;
    return Padding(
      padding: AppSpacing.page,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            codeStageReached
                ? Icons.error_outline_rounded
                : Icons.hourglass_top_rounded,
            size: 48,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: AppSpacing.md),
          AppText(
            codeStageReached
                ? 'QR code unavailable'
                : 'Waiting for arrival code confirmation',
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          AppText(
            codeStageReached
                ? 'The secure code could not be loaded. Apply the latest Supabase migration, then reopen this booking.'
                : 'The care seeker must confirm the caregiver code before the safety QR becomes available.',
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

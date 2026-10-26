import 'dart:convert';

import 'package:care_core/care_core.dart';
import 'package:care_ui/care_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager/ndef_record.dart';
import 'package:nfc_manager_ndef/nfc_manager_ndef.dart';

import '../../core/providers.dart';
import '../demo/demo_controls_sheet.dart';
import '../home/home_shell.dart';
import '../session/session_screen.dart';

/// Verifies the physical safety button handed over once the caregiver has
/// confirmed the caregiver's identity code. (FR-CS-13, FR-CS-14, FR-CS-15)
///
/// The [/scan-qr] and [/scan-nfc] routes share this screen. QR data is read by
/// the device camera; NFC data is read from a writable/readable NDEF tag.
class ScanSafetyButtonScreen extends ConsumerStatefulWidget {
  const ScanSafetyButtonScreen({super.key, required this.method});

  static const String qrRoute = '/scan-qr';
  static const String nfcRoute = '/scan-nfc';

  final ButtonVerificationMethod method;

  @override
  ConsumerState<ScanSafetyButtonScreen> createState() =>
      _ScanSafetyButtonScreenState();
}

class _ScanSafetyButtonScreenState
    extends ConsumerState<ScanSafetyButtonScreen> {
  bool _busy = false;
  bool _nfcStarted = false;
  String? _nfcMessage;

  bool get _isQr => widget.method == ButtonVerificationMethod.qr;

  String get _title =>
      _isQr ? 'Scan the safety button' : 'Read the safety button';

  Future<void> _verifyPayload(String payload) async {
    final booking = ref.read(activeBookingProvider).value;
    if (booking == null || _busy) {
      return;
    }
    setState(() => _busy = true);
    final result = await ref
        .read(platformProvider)
        .verifySafetyButton(
          ButtonVerification(method: widget.method, payload: payload),
        );
    if (!mounted) {
      return;
    }
    setState(() => _busy = false);
    if (result.success) {
      context.go(SessionScreen.route);
    } else {
      // The platform cancels the booking when the button does not match.
      await _showFailure(
        result.message ?? 'The safety button was not verified.',
      );
    }
  }

  Future<void> _simulateCorrectScan() async {
    if (_busy) return;
    setState(() => _busy = true);
    final result = await ref
        .read(platformProvider)
        .simulateButtonScanResult(method: widget.method);
    if (!mounted) return;
    setState(() => _busy = false);
    if (result.success) {
      context.go(SessionScreen.route);
    } else {
      await _showFailure(
        result.message ?? 'The simulated scan could not be verified.',
      );
    }
  }

  void _onQrDetected(BarcodeCapture capture) {
    final payload = capture.barcodes
        .map((barcode) => barcode.rawValue)
        .whereType<String>()
        .firstOrNull;
    if (payload != null && payload.isNotEmpty) {
      _verifyPayload(payload);
    }
  }

  Future<void> _startNfcScan() async {
    if (kIsWeb) {
      setState(
        () => _nfcMessage = 'NFC scanning needs the installed mobile app.',
      );
      return;
    }
    if (_nfcStarted || _busy) return;
    final availability = await NfcManager.instance.checkAvailability();
    if (!mounted) return;
    if (availability != NfcAvailability.enabled) {
      setState(
        () => _nfcMessage = availability == NfcAvailability.disabled
            ? 'Turn on NFC in your phone settings, then try again.'
            : 'This phone does not support NFC. Use the QR scanner instead.',
      );
      return;
    }

    setState(() {
      _nfcStarted = true;
      _nfcMessage = 'Hold the top of your phone near the care giver’s NFC tag.';
    });
    try {
      await NfcManager.instance.startSession(
        pollingOptions: const {NfcPollingOption.iso14443},
        alertMessageIos: 'Hold your phone near the safety button.',
        onDiscovered: (tag) async {
          try {
            final ndef = Ndef.from(tag);
            final message = ndef?.cachedMessage ?? await ndef?.read();
            final payload = message?.records
                .map(_decodeNdefText)
                .whereType<String>()
                .firstOrNull;
            await NfcManager.instance.stopSession();
            if (!mounted) return;
            setState(() {
              _nfcStarted = false;
              _nfcMessage = payload == null
                  ? 'This tag has no Care-Flash safety code. Try another tag.'
                  : null;
            });
            if (payload != null) await _verifyPayload(payload);
          } catch (error) {
            await NfcManager.instance.stopSession();
            if (mounted) {
              setState(() {
                _nfcStarted = false;
                _nfcMessage = 'Could not read the NFC tag: $error';
              });
            }
          }
        },
      );
    } catch (error) {
      if (mounted) {
        setState(() {
          _nfcStarted = false;
          _nfcMessage = 'Could not start NFC scanning: $error';
        });
      }
    }
  }

  String? _decodeNdefText(NdefRecord record) {
    if (record.typeNameFormat != TypeNameFormat.wellKnown ||
        record.type.length != 1 ||
        record.type.first != 0x54 ||
        record.payload.isEmpty) {
      return null;
    }
    final languageLength = record.payload.first & 0x3f;
    final textOffset = 1 + languageLength;
    if (textOffset > record.payload.length) return null;
    return utf8.decode(
      record.payload.sublist(textOffset),
      allowMalformed: true,
    );
  }

  @override
  void dispose() {
    if (_nfcStarted && !kIsWeb) {
      NfcManager.instance.stopSession();
    }
    super.dispose();
  }

  Future<void> _showFailure(String message) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const AppText('Safety button not verified'),
        content: AppText(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const AppText('Scan again'),
          ),
          AppButton(
            label: 'Back home',
            variant: AppButtonVariant.ghost,
            expand: false,
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.go(HomeShell.route);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final booking = ref.watch(activeBookingProvider).value;

    if (booking == null || !booking.canVerifyButton) {
      return Scaffold(
        appBar: AppBar(title: AppText(_title)),
        body: EmptyState(
          icon: _isQr ? Icons.qr_code_2_outlined : Icons.contactless_outlined,
          title: 'The safety button is not ready to verify yet.',
          actionLabel: 'Back home',
          onAction: () => context.go(HomeShell.route),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: AppText(_title),
        actions: [
          if (kDebugMode)
            IconButton(
              tooltip: trText(context, 'Demo controls'),
              icon: const Icon(Icons.bug_report_outlined),
              onPressed: () => showDemoControls(context),
            ),
        ],
      ),
      body: Padding(
        padding: AppSpacing.page,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: AppRadii.sheet,
                ),
                alignment: Alignment.center,
                child: _isQr
                    ? ClipRRect(
                        borderRadius: AppRadii.sheet,
                        child: MobileScanner(
                          onDetect: _onQrDetected,
                          errorBuilder: (context, error) => Center(
                            child: Padding(
                              padding: AppSpacing.page,
                              child: AppText(
                                'Camera unavailable. Allow camera access and reopen the scanner. ${error.errorCode.name}',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: Colors.white,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.contactless_rounded,
                            size: 72,
                            color: Colors.white70,
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          AppText(
                            'Tap below, then hold the top of your phone near the NFC tag.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.white70,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppText(
              'Your caregiver hands you the booking-linked safety button once '
              'you confirm their identity code. Scanning pairs it to this session.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            if (_isQr)
              AppText(
                'Point your camera at the QR code shown in Care-Merchant.',
                style: theme.textTheme.bodySmall,
                textAlign: TextAlign.center,
              )
            else ...[
              AppButton(
                label: _nfcStarted ? 'Waiting for NFC tag…' : 'Start NFC scan',
                icon: Icons.contactless_rounded,
                loading: _nfcStarted || _busy,
                onPressed: _nfcStarted || _busy ? null : _startNfcScan,
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
            // Debug controls remain available for demos without a physical tag.
            if (kDebugMode) ...[
              AppButton(
                label: 'Simulate a correct scan',
                icon: _isQr
                    ? Icons.qr_code_scanner_rounded
                    : Icons.contactless_rounded,
                loading: _busy,
                onPressed: _busy ? null : _simulateCorrectScan,
              ),
              if (booking.safetyButtonId == null) ...[
                const SizedBox(height: AppSpacing.xs),
                AppText(
                  'Demo simulation verifies the booking without a camera. For a real scan, use the live QR code in Care-Merchant.',
                  style: theme.textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: AppSpacing.sm),
              AppButton(
                label: 'I scanned a different button',
                variant: AppButtonVariant.ghost,
                onPressed: _busy ? null : () => _verifyPayload('WRONG-BUTTON'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

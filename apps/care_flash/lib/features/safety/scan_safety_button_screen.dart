import 'package:care_core/care_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../demo/demo_controls_sheet.dart';
import '../home/home_shell.dart';
import '../session/session_screen.dart';

/// Verifies the physical safety button handed over once the caregiver has
/// checked the client code. (FR-CS-13, FR-CS-14, FR-CS-15)
///
/// The [/scan-qr] and [/scan-nfc] routes share this screen; only the
/// verification method changes. The prototype has no camera or NFC reader, so
/// the read is simulated against the mock platform.
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

  bool get _isQr => widget.method == ButtonVerificationMethod.qr;

  String get _title => _isQr ? 'Scan the safety button' : 'Read the safety button';

  Future<void> _verify({required bool valid}) async {
    final booking = ref.read(activeBookingProvider).value;
    if (booking == null) {
      return;
    }
    setState(() => _busy = true);
    final result = await ref.read(platformProvider).verifySafetyButton(
          ButtonVerification(
            method: widget.method,
            payload: valid ? (booking.safetyButtonId ?? '') : 'WRONG-BUTTON',
          ),
        );
    if (!mounted) {
      return;
    }
    setState(() => _busy = false);
    if (result.success) {
      context.go(SessionScreen.route);
    } else {
      // The platform cancels the booking when the button does not match.
      await _showFailure(result.message ?? 'The safety button was not verified.');
    }
  }

  Future<void> _showFailure(String message) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Safety button not verified'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.go(HomeShell.route);
            },
            child: const Text('Back home'),
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
        appBar: AppBar(title: Text(_title)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _isQr ? Icons.qr_code_2_outlined : Icons.contactless_outlined,
                  size: 56,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 16),
                const Text(
                  'The safety button is not ready to verify yet.',
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
        title: Text(_title),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(20),
                ),
                alignment: Alignment.center,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isQr ? Icons.qr_code_scanner : Icons.contactless,
                        size: 72,
                        color: Colors.white70,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _isQr
                            ? 'Point the camera at the QR code on the safety button.'
                            : 'Hold the NFC tag close to the top of your phone.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white70,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Your caregiver hands you the booking-linked safety button once '
              'your client code is verified. Scanning pairs it to this session.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _busy ? null : () => _verify(valid: true),
              icon: _busy
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(_isQr ? Icons.qr_code_scanner : Icons.contactless),
              label: Text(_busy ? 'Checking…' : 'Simulate a correct scan'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _busy ? null : () => _verify(valid: false),
              child: const Text('I scanned a different button'),
            ),
          ],
        ),
      ),
    );
  }
}

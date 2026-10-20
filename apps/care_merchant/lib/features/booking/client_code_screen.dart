import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../home/home_shell.dart';
import 'button_handover_screen.dart';

/// Verifies the client code the care seeker presents at arrival. (FR-CM-13,
/// FR-CM-14)
///
/// A wrong code cancels the booking and notifies support, so the caregiver is
/// asked to re-check the code before submitting.
class ClientCodeScreen extends ConsumerStatefulWidget {
  const ClientCodeScreen({super.key});

  static const String route = '/booking/client-code';

  @override
  ConsumerState<ClientCodeScreen> createState() => _ClientCodeScreenState();
}

class _ClientCodeScreenState extends ConsumerState<ClientCodeScreen> {
  final _controller = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final code = _controller.text.trim();
    if (code.isEmpty) {
      setState(() => _error = 'Enter the client code the care seeker shows you.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final result = await ref.read(platformProvider).verifyClientCode(code);
    if (!mounted) {
      return;
    }
    setState(() => _busy = false);
    if (result.success) {
      context.pushReplacement(ButtonHandoverScreen.route);
    } else {
      // A wrong code cancels the booking, so send the caregiver home. (FR-CM-14)
      await _showFailure(result.message ?? 'The client code did not match.');
    }
  }

  Future<void> _showFailure(String message) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Verification failed'),
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
    final code = kDebugMode ? ref.read(platformProvider).debugClientCode : null;

    return Scaffold(
      appBar: AppBar(title: const Text('Client code')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(
                Icons.pin_outlined,
                size: 56,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'Ask the care seeker for their 6-digit client code.',
                style: theme.textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'The code confirms you are with the right care seeker. The '
                'session cannot start until it matches.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _controller,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                maxLength: 6,
                style: theme.textTheme.headlineMedium?.copyWith(
                  letterSpacing: 8,
                ),
                decoration: const InputDecoration(
                  labelText: 'Client code',
                  hintText: '000000',
                  counterText: '',
                ),
                onSubmitted: (_) => _busy ? null : _verify(),
              ),
              if (code != null) ...[
                const SizedBox(height: 8),
                // Debug only: another device would show this on the care
                // seeker's screen. (FR-CM-13)
                Text(
                  'Demo: the care seeker\'s code is $code',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              const Spacer(),
              FilledButton(
                onPressed: _busy || booking == null ? null : _verify,
                child: _busy
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Verify code'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

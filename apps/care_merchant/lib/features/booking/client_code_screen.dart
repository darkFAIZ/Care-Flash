import 'package:care_ui/care_ui.dart';
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
        title: const AppText('Verification failed'),
        content: AppText(message),
        actions: [
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
    final code = kDebugMode ? ref.read(platformProvider).debugClientCode : null;

    return Scaffold(
      appBar: AppBar(title: const AppText('Care seeker code')),
      body: SafeArea(
        child: Padding(
          padding: AppSpacing.page,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(
                Icons.pin_outlined,
                size: 56,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: AppSpacing.lg),
              AppText(
                'Ask the care seeker for their 6-digit client code.',
                style: theme.textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              AppText(
                "The code is created by the care seeker's app after payment. "
                'You type it in to verify the client: you never generate this '
                'code yourself. The session cannot start until it matches.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xl),
              TextField(
                controller: _controller,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                maxLength: 6,
                style: theme.textTheme.headlineMedium?.copyWith(
                  letterSpacing: 8,
                ),
                decoration: InputDecoration(
                  labelText: trText(context, 'Client code'),
                  hintText: '000000',
                  counterText: '',
                ),
                onSubmitted: (_) => _busy ? null : _verify(),
              ),
              if (code != null) ...[
                const SizedBox(height: AppSpacing.sm),
                // Debug only: another device would show this on the care
                // seeker's screen. (FR-CM-13)
                AppText(
                  'Demo: the care seeker\'s code is $code',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: AppSpacing.md),
                AppText(
                  _error!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppSemanticColors.of(context).danger,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              const Spacer(),
              AppButton(
                label: 'Verify code',
                loading: _busy,
                onPressed: _busy || booking == null ? null : _verify,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:care_core/care_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import 'confirmed_screen.dart';

/// The care seeker enters the code spoken by the assigned caregiver.
class CaregiverCodeScreen extends ConsumerStatefulWidget {
  const CaregiverCodeScreen({super.key});

  static const route = '/caregiver-code';

  @override
  ConsumerState<CaregiverCodeScreen> createState() =>
      _CaregiverCodeScreenState();
}

class _CaregiverCodeScreenState extends ConsumerState<CaregiverCodeScreen> {
  final _controller = TextEditingController();
  bool _busy = false;
  bool _navigating = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final result = await ref
        .read(platformProvider)
        .verifyCaregiverCode(_controller.text);
    if (!mounted) return;
    if (result.success) {
      _showConfirmed();
    } else {
      setState(() {
        _busy = false;
        _error =
            result.message ??
            'The code did not match. Please check with your caregiver.';
      });
    }
  }

  void _showConfirmed() {
    if (_navigating || !mounted) return;
    _navigating = true;
    context.go(ConfirmedScreen.route);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    ref.listen(activeBookingProvider, (previous, next) {
      if (next.value?.status == BookingStatus.codeVerified) _showConfirmed();
    });
    return Scaffold(
      appBar: AppBar(title: const Text('Confirm caregiver')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(
                Icons.shield_outlined,
                size: 56,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 20),
              Text(
                'Ask your caregiver to say their code',
                style: theme.textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Check that the code matches before you confirm their identity.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              TextField(
                controller: _controller,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineMedium?.copyWith(
                  letterSpacing: 10,
                  fontWeight: FontWeight.w700,
                ),
                decoration: const InputDecoration(
                  labelText: '6-digit caregiver code',
                  hintText: '••••••',
                ),
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) => _busy ? null : _confirm(),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: TextStyle(color: theme.colorScheme.error),
                  textAlign: TextAlign.center,
                ),
              ],
              const Spacer(),
              FilledButton.icon(
                onPressed: _busy || _controller.text.length != 6
                    ? null
                    : _confirm,
                icon: _busy
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.verified_outlined),
                label: const Text('Confirm caregiver'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

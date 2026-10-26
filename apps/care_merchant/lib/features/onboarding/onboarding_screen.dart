import 'package:care_ui/care_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import 'verification_status_screen.dart';

/// Submit Residential ID identification for platform review. (FR-CM-2)
///
/// The online prototype does not upload or store the ID number or document.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  static const String route = '/onboarding';

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _residentialId = TextEditingController();
  String? _documentLabel;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _residentialId.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_documentLabel == null) {
      setState(() => _error = 'Attach an identity card photo to continue.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    await ref.read(platformProvider).submitVerification(
          residentialIdNumber: _residentialId.text,
          documentLabel: _documentLabel!,
        );
    if (!mounted) {
      return;
    }
    setState(() => _busy = false);
    context.go(VerificationStatusScreen.route);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const AppText('Verify your account')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: AppSpacing.page,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppText(
                      'Caregivers are verified with a Residential ID.',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    AppText(
                      'Submit your Residential ID for review. This demo only records '
                      'the pending status; it does not upload or store your ID.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    AppTextField(
                      controller: _residentialId,
                      label: 'Residential ID number',
                      labelInside: true,
                      prefixIcon: Icons.badge_outlined,
                      keyboardType: TextInputType.number,
                      maxLength: 16,
                      inputFormatters: <TextInputFormatter>[
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      helperText: '16 digits, as printed on your Residential ID',
                      validator: (value) {
                        final digits = (value ?? '').trim();
                        if (digits.isEmpty) {
                          return 'Enter your Residential ID number';
                        }
                        if (!RegExp(r'^\d{16}$').hasMatch(digits)) {
                          return 'A Residential ID number has 16 digits';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    AppButton(
                      label: _documentLabel == null
                          ? 'Attach identity card photo'
                          : 'Attached: $_documentLabel',
                      icon: Icons.upload_file_outlined,
                      variant: AppButtonVariant.secondary,
                      onPressed: _busy
                          ? null
                          : () => setState(() {
                                // Demo placeholder: no document leaves the device.
                                // (DC-CM-3)
                                _documentLabel = 'identity-card.jpg';
                                _error = null;
                              }),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: AppSpacing.lg),
                      AppText(
                        _error!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppSemanticColors.of(context).danger,
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.lg),
                    AppButton(
                      label: 'Submit for review',
                      loading: _busy,
                      onPressed: _busy ? null : _submit,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

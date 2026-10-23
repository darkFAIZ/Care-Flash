import 'package:care_ui/care_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import 'verification_status_screen.dart';

/// Submit KTP identification for platform review. (FR-CM-2)
///
/// Documents are only transmitted through the platform's authorized services,
/// so this screen collects a reference rather than a real file upload in the
/// prototype. (DC-CM-3)
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  static const String route = '/onboarding';

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _ktp = TextEditingController();
  String? _documentLabel;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _ktp.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_documentLabel == null) {
      setState(() => _error = 'Attach a photo of your KTP to continue.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    await ref.read(platformProvider).submitVerification(
          ktpNumber: _ktp.text,
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
                      'Caregivers are verified with a KTP.',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    AppText(
                      'We review your KTP before you can receive requests. '
                      'This usually takes a short while.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    AppTextField(
                      controller: _ktp,
                      label: 'KTP number',
                      labelInside: true,
                      prefixIcon: Icons.badge_outlined,
                      keyboardType: TextInputType.number,
                      maxLength: 16,
                      inputFormatters: <TextInputFormatter>[
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      helperText: '16 digits, as printed on your KTP',
                      validator: (value) {
                        final digits = (value ?? '').trim();
                        if (digits.isEmpty) {
                          return 'Enter your KTP number';
                        }
                        if (!RegExp(r'^\d{16}$').hasMatch(digits)) {
                          return 'A KTP number has 16 digits';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    AppButton(
                      label: _documentLabel == null
                          ? 'Attach KTP photo'
                          : 'Attached: $_documentLabel',
                      icon: Icons.upload_file_outlined,
                      variant: AppButtonVariant.secondary,
                      onPressed: _busy
                          ? null
                          : () => setState(() {
                                // TODO(team): replace with a real file picker
                                // and the platform's document upload service.
                                // (DC-CM-3)
                                _documentLabel = 'KTP.jpg';
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

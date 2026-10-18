import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import 'verification_status_screen.dart';

/// Submit student identification for platform review. (FR-CM-2)
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
  final _studentId = TextEditingController();
  final _university = TextEditingController();
  String? _documentLabel;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _studentId.dispose();
    _university.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_documentLabel == null) {
      setState(() => _error = 'Attach a photo of your student ID to continue.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    await ref.read(platformProvider).submitVerification(
          studentIdNumber: _studentId.text,
          university: _university.text,
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
      appBar: AppBar(title: const Text('Verify your account')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Caregivers are verified students.',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'We review your student ID before you can receive requests. '
                      'This usually takes a short while.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _studentId,
                      decoration: const InputDecoration(
                        labelText: 'Student ID number',
                        prefixIcon: Icon(Icons.badge_outlined),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Enter your student ID number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _university,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'University',
                        prefixIcon: Icon(Icons.school_outlined),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Enter your university';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    OutlinedButton.icon(
                      onPressed: _busy
                          ? null
                          : () => setState(() {
                                // TODO(team): replace with a real file picker
                                // and the platform's document upload service.
                                // (DC-CM-3)
                                _documentLabel = 'KTM.jpg';
                                _error = null;
                              }),
                      icon: const Icon(Icons.upload_file_outlined),
                      label: Text(_documentLabel == null
                          ? 'Attach student ID photo'
                          : 'Attached: $_documentLabel'),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        _error!,
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: theme.colorScheme.error),
                      ),
                    ],
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _busy ? null : _submit,
                      child: _busy
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Submit for review'),
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

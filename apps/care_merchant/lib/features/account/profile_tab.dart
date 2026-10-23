import 'package:care_core/care_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../onboarding/safety_module_screen.dart';
import '../onboarding/verification_status_screen.dart';
import 'login_screen.dart';
import 'preferences_sheet.dart';

/// Profile page: availability, gender, verification and safety status, and log
/// out. (FR-CM-5, FR-CM-6)
class ProfileTab extends ConsumerWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final caregiver = ref.watch(caregiverStateProvider).value;

    if (caregiver == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final platform = ref.read(platformProvider);
    final available = caregiver.availability == CaregiverAvailability.available;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Text(
                    caregiver.name.isNotEmpty
                        ? caregiver.name[0].toUpperCase()
                        : '?',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(caregiver.name, style: theme.textTheme.titleLarge),
                      const SizedBox(height: 4),
                      Text(
                        caregiver.email,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          _badge(
                            theme,
                            caregiver.isVerified
                                ? 'Identity verified'
                                : 'Not verified',
                            caregiver.isVerified
                                ? Icons.verified_outlined
                                : Icons.info_outline,
                            ok: caregiver.isVerified,
                          ),
                          _badge(
                            theme,
                            caregiver.safetyModuleCompleted
                                ? 'Safety badge'
                                : 'No safety badge',
                            Icons.health_and_safety_outlined,
                            ok: caregiver.safetyModuleCompleted,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          SwitchListTile(
            secondary: Icon(
              available ? Icons.toggle_on : Icons.toggle_off,
              color: available ? theme.colorScheme.primary : null,
            ),
            title: const Text('Available for requests'),
            subtitle: const Text('Turn off to stop receiving new requests'),
            value: available,
            onChanged: (value) => platform.updateAvailability(
              value
                  ? CaregiverAvailability.available
                  : CaregiverAvailability.unavailable,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.wc_outlined),
            title: const Text('Gender'),
            subtitle: Text(caregiver.gender.label),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showGenderSheet(context, ref, caregiver),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.assignment_turned_in_outlined),
            title: const Text('Verification status'),
            subtitle: Text(caregiver.verificationStatus.label),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(VerificationStatusScreen.route),
          ),
          ListTile(
            leading: const Icon(Icons.health_and_safety_outlined),
            title: const Text('Safety module'),
            subtitle: Text(
              caregiver.safetyModuleCompleted ? 'Completed' : 'Not completed',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(SafetyModuleScreen.route),
          ),
          ListTile(
            leading: const Icon(Icons.star_outline),
            title: const Text('Rating'),
            subtitle: Text(caregiver.ratingLabel),
          ),
          ListTile(
            leading: const Icon(Icons.tune),
            title: const Text('Language and appearance'),
            subtitle: const Text('Language, light and dark mode'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => showMerchantPreferences(context),
          ),
          const Divider(height: 1),
          ListTile(
            leading: Icon(Icons.logout, color: theme.colorScheme.error),
            title: Text(
              'Log out',
              style: TextStyle(color: theme.colorScheme.error),
            ),
            onTap: () async {
              await platform.signOut();
              if (context.mounted) {
                context.go(LoginScreen.route);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _badge(
    ThemeData theme,
    String label,
    IconData icon, {
    required bool ok,
  }) {
    final color = ok ? theme.colorScheme.primary : theme.colorScheme.outline;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(color: color),
          ),
        ],
      ),
    );
  }

  void _showGenderSheet(
    BuildContext context,
    WidgetRef ref,
    CaregiverAccount caregiver,
  ) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Gender',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            ...Gender.values.map(
              (gender) => ListTile(
                leading: Icon(
                  gender == caregiver.gender
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                ),
                title: Text(gender.label),
                onTap: () {
                  ref.read(platformProvider).updateGender(gender);
                  Navigator.of(context).pop();
                },
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

import 'package:care_core/care_core.dart';
import 'package:care_ui/care_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/appearance.dart';
import '../../core/providers.dart';
import '../onboarding/safety_module_screen.dart';
import '../onboarding/verification_status_screen.dart';
import 'appearance_sheet.dart';
import 'edit_profile_screen.dart';
import 'language_sheet.dart';
import 'login_screen.dart';

/// Profile page: availability, gender, verification and safety status, and log
/// out. (FR-CM-5, FR-CM-6)
class ProfileTab extends ConsumerWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final caregiver = ref.watch(caregiverStateProvider).value;
    final appearance = ref.watch(appearanceProvider);
    final language = ref.watch(languageProvider);

    if (caregiver == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final platform = ref.read(platformProvider);
    final available = caregiver.availability == CaregiverAvailability.available;

    return Scaffold(
      appBar: AppBar(title: const AppText('Profile')),
      body: ListView(
        children: [
          Padding(
            padding: AppSpacing.page,
            child: Row(
              children: [
                UserAvatar(
                  name: caregiver.name,
                  avatarDataUrl: caregiver.avatarDataUrl,
                  radius: 32,
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText(caregiver.name, style: theme.textTheme.titleLarge),
                      const SizedBox(height: AppSpacing.xs),
                      AppText(
                        caregiver.email,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.xs,
                        children: [
                          StatusChip(
                            label: caregiver.isVerified
                                ? 'Verified identity'
                                : 'Not verified',
                            icon: caregiver.isVerified
                                ? Icons.verified_outlined
                                : Icons.info_outline,
                            tint: caregiver.isVerified
                                ? AppStatusTint.success
                                : AppStatusTint.neutral,
                          ),
                          StatusChip(
                            label: caregiver.safetyModuleCompleted
                                ? 'Safety badge'
                                : 'No safety badge',
                            icon: Icons.health_and_safety_outlined,
                            tint: caregiver.safetyModuleCompleted
                                ? AppStatusTint.success
                                : AppStatusTint.neutral,
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
          ListTile(
            leading: const Icon(Icons.edit_outlined),
            title: const AppText('Edit profile'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => context.push(EditProfileScreen.route),
          ),
          ListTile(
            leading: const Icon(Icons.palette_outlined),
            title: const AppText('Appearance'),
            subtitle: AppText(appearance.label),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => showAppearanceSheet(context),
          ),
          ListTile(
            leading: const Icon(Icons.language_rounded),
            title: const AppText('Language'),
            subtitle: AppText(language.label),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => showLanguageSheet(context),
          ),
          SwitchListTile(
            secondary: Icon(
              available ? Icons.toggle_on_rounded : Icons.toggle_off_rounded,
              color: available ? theme.colorScheme.primary : null,
            ),
            title: const AppText('Available for requests'),
            subtitle: const AppText('Turn off to stop receiving new requests'),
            value: available,
            onChanged: (value) => platform.updateAvailability(
              value
                  ? CaregiverAvailability.available
                  : CaregiverAvailability.unavailable,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.wc_outlined),
            title: const AppText('Gender'),
            subtitle: AppText(caregiver.gender.label),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showGenderSheet(context, ref, caregiver),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.assignment_turned_in_outlined),
            title: const AppText('Verification status'),
            subtitle: AppText(caregiver.verificationStatus.label),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(VerificationStatusScreen.route),
          ),
          ListTile(
            leading: const Icon(Icons.health_and_safety_outlined),
            title: const AppText('Safety module'),
            subtitle: AppText(
              caregiver.safetyModuleCompleted ? 'Completed' : 'Not completed',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(SafetyModuleScreen.route),
          ),
          ListTile(
            leading: const Icon(Icons.star_outline_rounded),
            title: const AppText('Rating'),
            subtitle: AppText(caregiver.ratingLabel),
          ),
          const Divider(height: 1),
          ListTile(
            leading: Icon(Icons.logout_rounded,
                color: AppSemanticColors.of(context).danger),
            title: AppText(
              'Log out',
              style: TextStyle(color: AppSemanticColors.of(context).danger),
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
              padding: AppSpacing.page,
              child: AppText(
                'Gender',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            ...Gender.values.map(
              (gender) => ListTile(
                leading: Icon(
                  gender == caregiver.gender
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_unchecked_rounded,
                ),
                title: AppText(gender.label),
                onTap: () {
                  ref.read(platformProvider).updateGender(gender);
                  Navigator.of(context).pop();
                },
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
  }
}

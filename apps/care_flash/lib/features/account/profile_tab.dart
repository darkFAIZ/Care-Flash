import 'package:care_ui/care_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/appearance.dart';
import '../../core/providers.dart';
import '../account/language_sheet.dart';
import '../account/settings_sheet.dart';
import '../payment_info/payment_info_screen.dart';
import '../support/help_support_screen.dart';
import 'appearance_sheet.dart';
import 'edit_profile_screen.dart';
import 'login_screen.dart';

/// Profile page with settings and language overlays. (FR-CS-2)
class ProfileTab extends ConsumerWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final user = ref.watch(authStateProvider).value;
    final language = ref.watch(languageProvider);
    final appearance = ref.watch(appearanceProvider);
    final danger = AppSemanticColors.of(context).danger;

    return Scaffold(
      appBar: AppBar(title: const AppText('Profile')),
      body: ListView(
        children: [
          Padding(
            padding: AppSpacing.page,
            child: Row(
              children: [
                UserAvatar(
                  name: user?.name ?? '?',
                  avatarDataUrl: user?.avatarDataUrl,
                  radius: 32,
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText(
                        user?.name ?? 'Care seeker',
                        style: theme.textTheme.titleLarge,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      AppText(
                        user?.email ?? '',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
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
            leading: const Icon(Icons.credit_card_rounded),
            title: const AppText('Payment info'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => context.push(PaymentInfoScreen.route),
          ),
          ListTile(
            leading: const Icon(Icons.support_agent_rounded),
            title: const AppText('Help and support'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => context.push(HelpSupportScreen.route),
          ),
          ListTile(
            leading: const Icon(Icons.language_rounded),
            title: const AppText('Language'),
            subtitle: AppText(language.label),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => showLanguageSheet(context),
          ),
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: const AppText('Settings'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => showSettingsSheet(context),
          ),
          const Divider(height: 1),
          ListTile(
            leading: Icon(Icons.logout_rounded, color: danger),
            title: AppText('Log out', style: TextStyle(color: danger)),
            onTap: () async {
              await ref.read(platformProvider).signOut();
              if (context.mounted) {
                context.go(LoginScreen.route);
              }
            },
          ),
        ],
      ),
    );
  }
}

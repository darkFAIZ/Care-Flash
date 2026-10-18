import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../account/language_sheet.dart';
import '../account/settings_sheet.dart';
import '../payment_info/payment_info_screen.dart';
import '../support/help_support_screen.dart';
import 'login_screen.dart';

/// Profile page with settings and language overlays. (FR-CS-2)
class ProfileTab extends ConsumerWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final user = ref.watch(authStateProvider).value;
    final language = ref.watch(languageProvider);

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
                    (user?.name.isNotEmpty ?? false)
                        ? user!.name[0].toUpperCase()
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
                      Text(
                        user?.name ?? 'Care seeker',
                        style: theme.textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
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
            leading: const Icon(Icons.credit_card),
            title: const Text('Payment info'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(PaymentInfoScreen.route),
          ),
          ListTile(
            leading: const Icon(Icons.support_agent),
            title: const Text('Help and support'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(HelpSupportScreen.route),
          ),
          ListTile(
            leading: const Icon(Icons.language),
            title: const Text('Language'),
            subtitle: Text(language.label),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => showLanguageSheet(context),
          ),
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: const Text('Settings'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => showSettingsSheet(context),
          ),
          const Divider(height: 1),
          ListTile(
            leading: Icon(Icons.logout, color: theme.colorScheme.error),
            title: Text(
              'Log out',
              style: TextStyle(color: theme.colorScheme.error),
            ),
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

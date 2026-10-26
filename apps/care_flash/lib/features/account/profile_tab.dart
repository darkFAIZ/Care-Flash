import 'package:care_ui/care_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/appearance.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../account/language_sheet.dart';
import '../account/settings_sheet.dart';
import '../payment_info/payment_info_screen.dart';
import '../support/help_support_screen.dart';
import 'appearance_sheet.dart';
import 'edit_profile_screen.dart';
import 'login_screen.dart';

/// Profile page matching Stitch profile_settings design. (FR-CS-2)
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
      appBar: AppBar(
        titleSpacing: AppSpacing.pageGutter,
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: WarmEmpathyColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.health_and_safety_rounded,
                color: WarmEmpathyColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'CarePulse',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: WarmEmpathyColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Profile',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: WarmEmpathyColors.onSurfaceVariant,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.pageGutter,
          vertical: AppSpacing.md,
        ),
        children: [
          // Top Profile Card Section
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: WarmEmpathyColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: WarmEmpathyColors.cardBorder),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x08000000),
                  offset: Offset(0, 2),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Column(
              children: [
                Stack(
                  children: [
                    Container(
                      width: 84,
                      height: 84,
                      decoration: const BoxDecoration(
                        color: WarmEmpathyColors.surfaceContainer,
                        shape: BoxShape.circle,
                      ),
                      child: UserAvatar(
                        name: user?.name ?? 'Care seeker',
                        avatarDataUrl: user?.avatarDataUrl,
                        radius: 42,
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: const BoxDecoration(
                          color: WarmEmpathyColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.photo_camera_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  user?.name ?? 'Care Seeker',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: WarmEmpathyColors.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  user?.email ?? 'care.seeker@example.com',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: WarmEmpathyColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  '+1 (555) 234-5678',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: WarmEmpathyColors.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: WarmEmpathyColors.secondaryContainer,
                    borderRadius: BorderRadius.circular(9999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.verified_rounded,
                        color: WarmEmpathyColors.primary,
                        size: 15,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Care Seeker Account • Verified',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: WarmEmpathyColors.onSecondaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // Care Pulse Wallet Quick Stat
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: WarmEmpathyColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: const BoxDecoration(
                              color: WarmEmpathyColors.surfaceContainerLowest,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.account_balance_wallet_rounded,
                              color: WarmEmpathyColors.secondary,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'CarePulse Credit Balance',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: WarmEmpathyColors.onSurfaceVariant,
                                ),
                              ),
                              Text(
                                '\$35.00',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: WarmEmpathyColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: WarmEmpathyColors.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(9999),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x06000000),
                              offset: Offset(0, 1),
                              blurRadius: 2,
                            ),
                          ],
                        ),
                        child: Text(
                          'Top Up',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: WarmEmpathyColors.secondary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Main Settings Stack matching Stitch
          Material(
            color: WarmEmpathyColors.surfaceContainerLowest,
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: WarmEmpathyColors.cardBorder),
            ),
            child: Column(
              children: [
                _settingsTile(
                  context,
                  icon: Icons.badge_outlined,
                  iconColor: WarmEmpathyColors.primary,
                  title: 'Edit profile',
                  subtitle: 'Personal contact & primary home address',
                  onTap: () => context.push(EditProfileScreen.route),
                ),
                const Divider(height: 1, indent: 64, color: WarmEmpathyColors.cardBorder),
                _settingsTile(
                  context,
                  icon: Icons.palette_outlined,
                  iconColor: WarmEmpathyColors.secondary,
                  title: 'Appearance',
                  subtitle: 'Themes & visual accessibility • ${appearance.label}',
                  onTap: () => showAppearanceSheet(context),
                ),
                const Divider(height: 1, indent: 64, color: WarmEmpathyColors.cardBorder),
                _settingsTile(
                  context,
                  icon: Icons.credit_card_rounded,
                  iconColor: WarmEmpathyColors.primary,
                  title: 'Payment info',
                  subtitle: 'Cards, Apple Pay & credit balance',
                  onTap: () => context.push(PaymentInfoScreen.route),
                ),
                const Divider(height: 1, indent: 64, color: WarmEmpathyColors.cardBorder),
                _settingsTile(
                  context,
                  icon: Icons.support_agent_rounded,
                  iconColor: WarmEmpathyColors.primary,
                  title: 'Help and support',
                  subtitle: 'Help desk, chat & FAQs',
                  onTap: () => context.push(HelpSupportScreen.route),
                ),
                const Divider(height: 1, indent: 64, color: WarmEmpathyColors.cardBorder),
                _settingsTile(
                  context,
                  icon: Icons.language_rounded,
                  iconColor: WarmEmpathyColors.secondary,
                  title: 'Language',
                  subtitle: 'Select app language • ${language.label}',
                  onTap: () => showLanguageSheet(context),
                ),
                const Divider(height: 1, indent: 64, color: WarmEmpathyColors.cardBorder),
                _settingsTile(
                  context,
                  icon: Icons.settings_outlined,
                  iconColor: WarmEmpathyColors.onSurfaceVariant,
                  title: 'Settings',
                  subtitle: 'Notifications, privacy & app preferences',
                  onTap: () => showSettingsSheet(context),
                ),
                const Divider(height: 1, indent: 64, color: WarmEmpathyColors.cardBorder),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: danger.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.logout_rounded, color: danger, size: 20),
                  ),
                  title: Text(
                    'Log out',
                    style: TextStyle(
                      color: danger,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  subtitle: Text(
                    'Sign out of your care seeker account',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: WarmEmpathyColors.onSurfaceVariant,
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded, color: WarmEmpathyColors.outline),
                  onTap: () async {
                    await ref.read(platformProvider).signOut();
                    if (context.mounted) {
                      context.go(LoginScreen.route);
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  Widget _settingsTile(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: WarmEmpathyColors.surfaceContainerLow,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: WarmEmpathyColors.onSurface,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: theme.textTheme.bodySmall?.copyWith(
          color: WarmEmpathyColors.onSurfaceVariant,
        ),
      ),
      trailing: const Icon(Icons.chevron_right_rounded, color: WarmEmpathyColors.outline),
      onTap: onTap,
    );
  }
}

import 'package:care_ui/care_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../home/home_shell.dart';
import 'login_screen.dart';

/// Logo/splash page shown when the app opens. Sends the user to home if they
/// are already signed in, otherwise to login. (FR-CS-1)
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  static const String route = '/splash';

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    if (!mounted) {
      return;
    }
    final signedIn = ref.read(platformProvider).currentUser != null;
    context.go(signedIn ? HomeShell.route : LoginScreen.route);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.primaryContainer,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 48,
              backgroundColor: theme.colorScheme.primary,
              child: Icon(
                Icons.health_and_safety_outlined,
                size: 52,
                color: theme.colorScheme.onPrimary,
              ),
            )
                .animate()
                .fadeIn(duration: 400.ms, delay: 100.ms)
                .scale(
                  begin: const Offset(0.9, 0.9),
                  end: const Offset(1, 1),
                  duration: 400.ms,
                  delay: 100.ms,
                  curve: Curves.easeOutBack,
                ),
            const SizedBox(height: AppSpacing.lg),
            AppText(
              'Care-Flash',
              style: theme.textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ).animate().fadeIn(delay: 300.ms),
            const SizedBox(height: AppSpacing.sm),
            AppText(
              'Help nearby, when you need it.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ).animate().fadeIn(delay: 450.ms),
            const SizedBox(height: AppSpacing.xl),
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 3),
            ).animate().fadeIn(delay: 600.ms),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

class SupabaseConnectionScreen extends StatelessWidget {
  const SupabaseConnectionScreen({super.key, required this.appName, required this.error, required this.onRetry, required this.onUseOffline});
  final String appName;
  final String error;
  final VoidCallback onRetry;
  final VoidCallback onUseOffline;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.cloud_off_rounded, size: 52, color: theme.colorScheme.primary),
                  const SizedBox(height: 16),
                  Text('$appName cannot start its Supabase connection', textAlign: TextAlign.center, style: theme.textTheme.titleLarge),
                  const SizedBox(height: 12),
                  Text('Build both apps with the same Supabase project URL and publishable key. The key is public and belongs in the app; never use a secret or service-role key here.', textAlign: TextAlign.center, style: theme.textTheme.bodyMedium),
                  const SizedBox(height: 16),
                  SelectableText(error, style: theme.textTheme.bodySmall?.copyWith(fontFamily: 'monospace')),
                  const SizedBox(height: 20),
                  FilledButton(onPressed: onRetry, child: const Text('Retry connection')),
                  const SizedBox(height: 8),
                  TextButton(onPressed: onUseOffline, child: const Text('Continue in offline demo')),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

/// Clear startup guidance when an app is configured for the shared backend but
/// cannot reach it yet.
class BackendConnectionScreen extends StatefulWidget {
  const BackendConnectionScreen({
    required this.appName,
    required this.backendUrl,
    required this.error,
    required this.onRetry,
    required this.onUseOffline,
    super.key,
  });

  final String appName;
  final String backendUrl;
  final String error;
  final Future<void> Function() onRetry;
  final Future<void> Function() onUseOffline;

  @override
  State<BackendConnectionScreen> createState() =>
      _BackendConnectionScreenState();
}

class _BackendConnectionScreenState extends State<BackendConnectionScreen> {
  bool _busy = false;

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    await action();
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final host = Uri.tryParse(widget.backendUrl)?.host.toLowerCase();
    final isLoopback =
        host == 'localhost' || host == '127.0.0.1' || host == '::1';
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(Icons.cloud_off_rounded, size: 58, color: scheme.error),
                  const SizedBox(height: 20),
                  Text(
                    'Shared backend not reachable',
                    style: theme.textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isLoopback
                        ? '${widget.appName} is set to ${widget.backendUrl}. '
                              'On a phone, localhost means the phone itself. '
                              'Rebuild this app with your public backend URL '
                              '(wss://...) and use that same URL for both apps.'
                        : '${widget.appName} could not connect to '
                              '${widget.backendUrl}. Check that the backend is '
                              'deployed and reachable, then confirm both apps '
                              'use this exact same URL.',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: SelectableText(
                        isLoopback
                            ? 'flutter build apk --release '
                                  '--dart-define=BACKEND_URL='
                                  'wss://YOUR-BACKEND.onrender.com\n\n'
                                  'Install the newly built APK on your phone. '
                                  'Repeat for both apps with the same backend URL.\n\n'
                                  'Connection error: ${widget.error}'
                            : 'Backend URL: ${widget.backendUrl}\n\n'
                                  'Connection error: ${widget.error}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: _busy ? null : () => _run(widget.onRetry),
                    icon: _busy
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.refresh_rounded),
                    label: Text(_busy ? 'Connecting…' : 'Retry connection'),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _busy ? null : () => _run(widget.onUseOffline),
                    child: const Text('Use offline demo instead'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

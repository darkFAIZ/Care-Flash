import 'package:care_core/care_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../home/home_shell.dart';

/// Reports the care seeker with evidence during or after a session. (FR-CM-20)
///
/// The prototype has no file picker, so evidence is attached as labelled
/// placeholders. The description is required.
class ReportCareSeekerScreen extends ConsumerStatefulWidget {
  const ReportCareSeekerScreen({super.key});

  static const String route = '/booking/report';

  @override
  ConsumerState<ReportCareSeekerScreen> createState() =>
      _ReportCareSeekerScreenState();
}

class _ReportCareSeekerScreenState
    extends ConsumerState<ReportCareSeekerScreen> {
  final _description = TextEditingController();
  final List<EvidenceAttachment> _evidence = [];
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _description.dispose();
    super.dispose();
  }

  void _addEvidence(EvidenceKind kind) {
    // TODO(team): replace with a real camera/gallery picker and size limits.
    // (FR-CM-20, SRS §4)
    setState(() {
      _evidence.add(
        EvidenceAttachment(
          id: 'ev-${_evidence.length + 1}',
          kind: kind,
          label: kind == EvidenceKind.photo
              ? 'Photo ${_evidence.length + 1}'
              : kind == EvidenceKind.video
                  ? 'Video ${_evidence.length + 1}'
                  : 'Note ${_evidence.length + 1}',
          addedAt: DateTime.now(),
        ),
      );
    });
  }

  Future<void> _submit(Booking booking) async {
    if (_description.text.trim().isEmpty) {
      setState(() => _error = 'Describe what happened before submitting.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    await ref.read(platformProvider).reportCareSeeker(
          IncidentReport(
            bookingId: booking.id,
            description: _description.text.trim(),
            createdAt: DateTime.now(),
            evidence: List.unmodifiable(_evidence),
          ),
        );
    if (!mounted) {
      return;
    }
    setState(() => _busy = false);
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Report sent'),
        content: const Text(
          'Support received your report and evidence. The session ended.',
        ),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.go(HomeShell.route);
            },
            child: const Text('Back home'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final booking = ref.watch(activeBookingProvider).value;
    final active = booking != null && booking.isSessionActive;

    return Scaffold(
      appBar: AppBar(title: const Text('Report the care seeker')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    'Tell us what happened. Your report goes to support and the '
                    'care seeker is not shown your identity.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _description,
                    maxLines: 5,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'What happened?',
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Evidence', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _addButton(Icons.photo_outlined, 'Add photo',
                          () => _addEvidence(EvidenceKind.photo)),
                      _addButton(Icons.videocam_outlined, 'Add video',
                          () => _addEvidence(EvidenceKind.video)),
                      _addButton(Icons.note_add_outlined, 'Add note',
                          () => _addEvidence(EvidenceKind.note)),
                    ],
                  ),
                  if (_evidence.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    ..._evidence.map(
                      (item) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          switch (item.kind) {
                            EvidenceKind.photo => Icons.photo_outlined,
                            EvidenceKind.video => Icons.videocam_outlined,
                            EvidenceKind.note => Icons.note_outlined,
                          },
                        ),
                        title: Text(item.label),
                        trailing: IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () =>
                              setState(() => _evidence.remove(item)),
                        ),
                      ),
                    ),
                  ],
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _error!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: FilledButton(
                onPressed: _busy || !active ? null : () => _submit(booking),
                child: _busy
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Submit report'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _addButton(IconData icon, String label, VoidCallback onTap) =>
      OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon),
        label: Text(label),
      );
}

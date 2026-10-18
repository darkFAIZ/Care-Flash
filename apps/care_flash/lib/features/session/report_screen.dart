import 'package:care_core/care_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../rating/rating_screen.dart';

/// Reports an incident during a session, ending it and refunding the care
/// seeker. Evidence capture is a placeholder until the team decides on types,
/// limits and retention. (FR-CS-17, FR-CS-18)
class ReportScreen extends ConsumerStatefulWidget {
  const ReportScreen({super.key});

  static const String route = '/report';

  @override
  ConsumerState<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends ConsumerState<ReportScreen> {
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
    setState(() {
      _evidence.add(
        EvidenceAttachment(
          id: 'ev-${_evidence.length + 1}',
          kind: kind,
          label: '${kind.label} ${_evidence.length + 1}',
          addedAt: DateTime.now(),
        ),
      );
    });
  }

  void _removeEvidence(EvidenceAttachment attachment) {
    setState(() => _evidence.remove(attachment));
  }

  Future<void> _submit() async {
    final booking = ref.read(activeBookingProvider).value;
    if (booking == null) {
      setState(() => _error = 'This session is no longer active.');
      return;
    }
    if (_description.text.trim().isEmpty) {
      setState(() => _error = 'Please describe what happened.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    await ref.read(platformProvider).reportIncident(
          IncidentReport(
            bookingId: booking.id,
            description: _description.text.trim(),
            createdAt: DateTime.now(),
            evidence: List<EvidenceAttachment>.unmodifiable(_evidence),
          ),
        );
    if (!mounted) {
      return;
    }
    setState(() => _busy = false);
    context.go(RatingScreen.route);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Report a problem')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: theme.colorScheme.errorContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded,
                      color: theme.colorScheme.onErrorContainer),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Sending a report ends the session and refunds your '
                      'payment. The safety team is notified straight away.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('What happened?', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          TextField(
            controller: _description,
            maxLines: 4,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              hintText: 'Describe the incident so support can follow up.',
            ),
          ),
          const SizedBox(height: 16),
          Text('Evidence', style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            'Photos, videos and notes help support resolve this faster.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ActionChip(
                avatar: const Icon(Icons.photo_camera_outlined, size: 18),
                label: const Text('Add photo'),
                onPressed: () => _addEvidence(EvidenceKind.photo),
              ),
              ActionChip(
                avatar: const Icon(Icons.videocam_outlined, size: 18),
                label: const Text('Add video'),
                onPressed: () => _addEvidence(EvidenceKind.video),
              ),
              ActionChip(
                avatar: const Icon(Icons.note_add_outlined, size: 18),
                label: const Text('Add note'),
                onPressed: () => _addEvidence(EvidenceKind.note),
              ),
            ],
          ),
          if (_evidence.isNotEmpty) ...[
            const SizedBox(height: 8),
            for (final item in _evidence)
              ListTile(
                dense: true,
                leading: Icon(_evidenceIcon(item.kind)),
                title: Text(item.label),
                trailing: IconButton(
                  tooltip: 'Remove',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _removeEvidence(item),
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
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: FilledButton(
            onPressed: _busy ? null : _submit,
            child: _busy
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Send report'),
          ),
        ),
      ),
    );
  }

  IconData _evidenceIcon(EvidenceKind kind) => switch (kind) {
        EvidenceKind.photo => Icons.photo_outlined,
        EvidenceKind.video => Icons.videocam_outlined,
        EvidenceKind.note => Icons.sticky_note_2_outlined,
      };
}

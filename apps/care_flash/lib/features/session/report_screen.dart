import 'package:care_core/care_core.dart';
import 'package:care_ui/care_ui.dart';
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
    final danger = AppSemanticColors.of(context).danger;
    return Scaffold(
      appBar: AppBar(title: const AppText('Report a problem')),
      body: ListView(
        padding: AppSpacing.page,
        children: [
          Card(
            color: theme.colorScheme.errorContainer,
            child: Padding(
              padding: AppSpacing.page,
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded,
                      color: theme.colorScheme.onErrorContainer),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: AppText(
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
          const SizedBox(height: AppSpacing.lg),
          const SectionHeader(title: 'What happened?'),
          const SizedBox(height: AppSpacing.xs),
          TextField(
            controller: _description,
            maxLines: 4,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText: trText(context, 'Describe the incident so support can follow up.'),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const SectionHeader(
            title: 'Evidence',
            subtitle: 'Photos, videos and notes help support resolve this '
                'faster.',
          ),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              ActionChip(
                avatar: const Icon(Icons.photo_camera_outlined, size: 18),
                label: const AppText('Add photo'),
                onPressed: () => _addEvidence(EvidenceKind.photo),
              ),
              ActionChip(
                avatar: const Icon(Icons.videocam_outlined, size: 18),
                label: const AppText('Add video'),
                onPressed: () => _addEvidence(EvidenceKind.video),
              ),
              ActionChip(
                avatar: const Icon(Icons.note_add_outlined, size: 18),
                label: const AppText('Add note'),
                onPressed: () => _addEvidence(EvidenceKind.note),
              ),
            ],
          ),
          if (_evidence.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            for (final item in _evidence)
              ListTile(
                dense: true,
                leading: Icon(_evidenceIcon(item.kind)),
                title: AppText(item.label),
                trailing: IconButton(
                  tooltip: trText(context, 'Remove'),
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _removeEvidence(item),
                ),
              ),
          ],
          if (_error != null) ...[
            const SizedBox(height: AppSpacing.md),
            AppText(
              _error!,
              style: theme.textTheme.bodyMedium?.copyWith(color: danger),
            ),
          ],
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.pageGutter,
            AppSpacing.sm,
            AppSpacing.pageGutter,
            AppSpacing.lg,
          ),
          child: AppButton(
            label: 'Send report',
            variant: AppButtonVariant.danger,
            loading: _busy,
            onPressed: _busy ? null : _submit,
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

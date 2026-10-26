import 'package:care_core/care_core.dart';
import 'package:care_ui/care_ui.dart';
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
        title: const AppText('Report sent'),
        content: const AppText(
          'Support received your report and evidence. The session ended.',
        ),
        actions: [
          AppButton(
            label: 'Back home',
            expand: false,
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.go(HomeShell.route);
            },
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
      appBar: AppBar(title: const AppText('Report the care seeker')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: AppSpacing.page,
                children: [
                  AppText(
                    'Tell us what happened. Your report goes to support and the '
                    'care seeker is not shown your identity.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  TextField(
                    controller: _description,
                    maxLines: 5,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      labelText: trText(context, 'What happened?'),
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppText('Evidence', style: theme.textTheme.titleMedium),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
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
                    const SizedBox(height: AppSpacing.sm),
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
                        title: AppText(item.label),
                        trailing: IconButton(
                          tooltip: trText(context, 'Remove ${item.label}'),
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () =>
                              setState(() => _evidence.remove(item)),
                        ),
                      ),
                    ),
                  ],
                  if (_error != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    AppText(
                      _error!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppSemanticColors.of(context).danger,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.pageGutter,
                AppSpacing.sm,
                AppSpacing.pageGutter,
                AppSpacing.lg,
              ),
              child: AppButton(
                label: 'Submit report',
                variant: AppButtonVariant.danger,
                loading: _busy,
                onPressed: _busy || !active ? null : () => _submit(booking),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _addButton(IconData icon, String label, VoidCallback onTap) =>
      AppButton(
        label: label,
        icon: icon,
        variant: AppButtonVariant.secondary,
        expand: false,
        onPressed: onTap,
      );
}

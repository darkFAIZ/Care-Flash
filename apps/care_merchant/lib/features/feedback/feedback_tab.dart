import 'package:care_core/care_core.dart';
import 'package:care_ui/care_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../common/star_rating.dart';

/// Feedback page: a prompt to rate the care seeker after a visit, plus the
/// feedback the care seeker left about this caregiver. (FR-CM-23, FR-CM-24,
/// FR-P-27)
class FeedbackTab extends ConsumerWidget {
  const FeedbackTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final feedback = ref.watch(feedbackReceivedProvider).value ??
        const <FeedbackReceived>[];
    final ratings = ref.watch(careSeekerRatingsProvider).value ??
        const <CareSeekerRating>[];
    final history = ref.watch(bookingHistoryProvider).value ?? const <Booking>[];

    final ratedIds = ratings.map((rating) => rating.bookingId).toSet();
    final unrated = _firstUnratedVisit(history, ratedIds);

    return Scaffold(
      appBar: AppBar(title: const AppText('Feedback')),
      body: ListView(
        padding: AppSpacing.page,
        children: [
          if (unrated != null) ...[
            _RatePromptCard(booking: unrated),
            const SizedBox(height: AppSpacing.xl),
          ],
          const SectionHeader(
            title: 'Feedback received',
            subtitle: 'Care seekers can rate you after every visit.',
            padding: EdgeInsets.zero,
          ),
          if (feedback.isEmpty)
            const AppCard(
              child: Row(
                children: [
                  Icon(Icons.inbox_outlined),
                  SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: AppText(
                      'Ratings and notes from care seekers will appear here '
                      'after your visits.',
                    ),
                  ),
                ],
              ),
            )
          else
            ...feedback.map(
              (item) => AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _Stars(value: item.stars),
                        const Spacer(),
                        AppText(
                          _formatDate(item.receivedAt),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    if (item.comment != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      AppText(item.comment!, style: theme.textTheme.bodyMedium),
                    ],
                    const SizedBox(height: AppSpacing.sm),
                    AppText(
                      item.reference,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// The most recent finished visit the caregiver has not rated yet. Only a
  /// visit that actually ran is offered for rating. (FR-CM-24)
  Booking? _firstUnratedVisit(List<Booking> history, Set<String> ratedIds) {
    for (final booking in history) {
      if (ratedIds.contains(booking.id)) {
        continue;
      }
      final outcome = booking.outcome;
      if (outcome == SessionOutcome.completed ||
          outcome == SessionOutcome.endedEarly) {
        return booking;
      }
    }
    return null;
  }
}

String _formatDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day/$month/${date.year}';
}

/// A read-only star row for showing feedback someone else left. (FR-CM-23)
class _Stars extends StatelessWidget {
  const _Stars({required this.value});

  final int value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var star = 1; star <= 5; star++)
          Icon(
            star <= value ? Icons.star_rounded : Icons.star_outline_rounded,
            size: 20,
            color: star <= value ? Colors.amber : theme.colorScheme.outline,
          ),
      ],
    );
  }
}

/// Opens the care-seeker rating sheet. (FR-CM-24)
Future<void> showRateCareSeekerSheet(BuildContext context, Booking booking) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => _RateCareSeekerSheet(booking: booking),
  );
}

class _RatePromptCard extends StatelessWidget {
  const _RatePromptCard({required this.booking});

  final Booking booking;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.primaryContainer,
      child: Padding(
        padding: AppSpacing.page,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  Icons.rate_review_outlined,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: AppText(
                    'Rate the care seeker',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            AppText(
              '${booking.requestReference} · ${booking.helpType.label}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            AppButton(
              label: 'Rate',
              expand: false,
              onPressed: () => showRateCareSeekerSheet(context, booking),
            ),
          ],
        ),
      ),
    );
  }
}

class _RateCareSeekerSheet extends ConsumerStatefulWidget {
  const _RateCareSeekerSheet({required this.booking});

  final Booking booking;

  @override
  ConsumerState<_RateCareSeekerSheet> createState() =>
      _RateCareSeekerSheetState();
}

class _RateCareSeekerSheetState extends ConsumerState<_RateCareSeekerSheet> {
  int _stars = 0;
  final _comment = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_stars == 0) {
      setState(() => _error = 'Choose a star rating first.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    await ref.read(platformProvider).rateCareSeeker(
          CareSeekerRating(
            bookingId: widget.booking.id,
            reference: widget.booking.requestReference,
            stars: _stars,
            comment: _comment.text.trim().isEmpty
                ? null
                : _comment.text.trim(),
          ),
        );
    if (!mounted) {
      return;
    }
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: AppText('Thanks for rating this care seeker.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.pageGutter,
          0,
          AppSpacing.pageGutter,
          MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppText('Rate this care seeker', style: theme.textTheme.titleLarge),
            const SizedBox(height: AppSpacing.xs),
            AppText(
              widget.booking.requestReference,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            StarRating(
              value: _stars,
              onChanged: (stars) => setState(() {
                _stars = stars;
                _error = null;
              }),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _comment,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: trText(context, 'Leave a note (optional)'),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.md),
              AppText(
                _error!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppSemanticColors.of(context).danger,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              label: 'Submit rating',
              loading: _busy,
              onPressed: _busy ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:care_core/care_core.dart';
import 'package:care_ui/care_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../common/star_rating.dart';
import '../home/home_shell.dart';

/// Rates the caregiver and leaves feedback about the app after a session ends.
/// (FR-CS-19, FR-CS-20)
class RatingScreen extends ConsumerStatefulWidget {
  const RatingScreen({super.key});

  static const String route = '/rating';

  @override
  ConsumerState<RatingScreen> createState() => _RatingScreenState();
}

class _RatingScreenState extends ConsumerState<RatingScreen> {
  int _caregiverStars = 0;
  int _appStars = 0;
  final _caregiverComment = TextEditingController();
  final _appComment = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _caregiverComment.dispose();
    _appComment.dispose();
    super.dispose();
  }

  Future<void> _submit(Booking booking, Caregiver caregiver) async {
    if (_caregiverStars == 0 || _appStars == 0) {
      setState(() => _error = 'Please rate both the caregiver and the app.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final platform = ref.read(platformProvider);
    var submitted = false;
    try {
      await platform.rateCaregiver(
        CaregiverRating(
          bookingId: booking.id,
          caregiverId: caregiver.id,
          stars: _caregiverStars,
          comment: _caregiverComment.text.trim().isEmpty
              ? null
              : _caregiverComment.text.trim(),
        ),
      );
      await platform.submitAppFeedback(
        AppFeedback(
          stars: _appStars,
          comment: _appComment.text.trim().isEmpty
              ? null
              : _appComment.text.trim(),
        ),
      );
      submitted = true;
    } catch (error, stackTrace) {
      debugPrint('Failed to submit post-session feedback: $error\n$stackTrace');
      if (mounted) {
        setState(
          () => _error = trText(
            context,
            'We could not submit your feedback. Please check your connection and try again.',
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
    if (submitted && mounted) {
      context.go(HomeShell.route);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final history =
        ref.watch(bookingHistoryProvider).value ?? const <Booking>[];
    final booking = history.isEmpty ? null : history.first;
    final caregiver = booking?.caregiver;

    if (booking == null || caregiver == null) {
      return Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const AppText('Thank you'),
        ),
        body: EmptyState(
          icon: Icons.favorite_rounded,
          title: 'Thank you for using Care-Flash.',
          actionLabel: 'Back home',
          onAction: () => context.go(HomeShell.route),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const AppText('Rate your visit'),
      ),
      body: ListView(
        padding: AppSpacing.page,
        children: [
          AppText(
            'How was ${caregiver.firstName}?',
            style: theme.textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          StarRating(
            value: _caregiverStars,
            onChanged: (stars) => setState(() => _caregiverStars = stars),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _caregiverComment,
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText: trText(
                context,
                'Leave a note about the visit (optional)',
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const Divider(),
          const SizedBox(height: AppSpacing.lg),
          AppText(
            'How was the Care-Flash app?',
            style: theme.textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          StarRating(
            value: _appStars,
            onChanged: (stars) => setState(() => _appStars = stars),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _appComment,
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText: trText(context, 'Tell us what to improve (optional)'),
            ),
          ),
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_error != null) ...[
                AppText(
                  _error!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppSemanticColors.of(context).danger,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
              AppButton(
                label: 'Submit',
                loading: _busy,
                onPressed: _busy ? null : () => _submit(booking, caregiver),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

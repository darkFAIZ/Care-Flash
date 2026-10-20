import 'package:care_core/care_core.dart';
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
    if (!mounted) {
      return;
    }
    setState(() => _busy = false);
    context.go(HomeShell.route);
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
          title: const Text('Thank you'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.favorite, size: 56, color: theme.colorScheme.primary),
                const SizedBox(height: 16),
                const Text(
                  'Thank you for using Care-Flash.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () => context.go(HomeShell.route),
                  child: const Text('Back home'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Rate your visit'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'How was ${caregiver.firstName}?',
            style: theme.textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          StarRating(
            value: _caregiverStars,
            onChanged: (stars) => setState(() => _caregiverStars = stars),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _caregiverComment,
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              hintText: 'Leave a note about the visit (optional)',
            ),
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),
          Text(
            'How was the Care-Flash app?',
            style: theme.textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          StarRating(
            value: _appStars,
            onChanged: (stars) => setState(() => _appStars = stars),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _appComment,
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              hintText: 'Tell us what to improve (optional)',
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 16),
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
            onPressed: _busy
                ? null
                : () => _submit(booking, caregiver),
            child: _busy
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Submit'),
          ),
        ),
      ),
    );
  }
}

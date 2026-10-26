import 'package:flutter/material.dart';

import '../tokens/spacing.dart';
import 'app_text.dart';

/// The six stops every booking passes through, in order.
///
/// Apps map their own booking state onto one of these; the timeline itself
/// knows nothing about pricing, codes or the backend.
enum BookingStage { paid, accepted, onTheWay, arrived, verified, active }

extension BookingStageInfo on BookingStage {
  String get label => switch (this) {
    BookingStage.paid => 'Paid',
    BookingStage.accepted => 'Accepted',
    BookingStage.onTheWay => 'On the way',
    BookingStage.arrived => 'Arrived',
    BookingStage.verified => 'Code verified',
    BookingStage.active => 'In progress',
  };

  IconData get icon => switch (this) {
    BookingStage.paid => Icons.payments_rounded,
    BookingStage.accepted => Icons.handshake_rounded,
    BookingStage.onTheWay => Icons.directions_car_rounded,
    BookingStage.arrived => Icons.location_on_rounded,
    BookingStage.verified => Icons.verified_rounded,
    BookingStage.active => Icons.play_circle_rounded,
  };
}

/// Vertical progress of a booking: everything up to [current] is done,
/// [current] is highlighted, the rest is greyed out.
class BookingTimeline extends StatelessWidget {
  const BookingTimeline({super.key, required this.current, this.stages});

  final BookingStage current;
  final List<BookingStage>? stages;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final all = stages ?? BookingStage.values;
    final index = all.indexOf(current);
    final currentIndex = index < 0 ? 0 : index;

    return Column(
      children: [
        for (var i = 0; i < all.length; i++) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 32,
                child: Column(
                  children: [
                    _StageDot(stage: all[i], state: _stageState(i, currentIndex)),
                    if (i != all.length - 1)
                      Container(
                        width: 2,
                        height: 22,
                        color: i < currentIndex ? scheme.primary : scheme.outlineVariant,
                      ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 5),
                  child: AppText(
                    all[i].label,
                    style: textTheme.titleSmall?.copyWith(
                      color: i <= currentIndex
                          ? scheme.onSurface
                          : scheme.onSurfaceVariant,
                      fontWeight: i == currentIndex ? FontWeight.w700 : FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  _StageState _stageState(int i, int current) {
    if (i < current) return _StageState.done;
    if (i == current) return _StageState.current;
    return _StageState.upcoming;
  }
}

enum _StageState { done, current, upcoming }

class _StageDot extends StatelessWidget {
  const _StageDot({required this.stage, required this.state});

  final BookingStage stage;
  final _StageState state;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    const double size = 32;

    final Widget child = switch (state) {
      _StageState.done => Icon(Icons.check_rounded, size: 18, color: scheme.onPrimary),
      _StageState.current => Icon(stage.icon, size: 17, color: scheme.onPrimary),
      _StageState.upcoming => Icon(stage.icon, size: 17, color: scheme.onSurfaceVariant),
    };

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: switch (state) {
          _StageState.done || _StageState.current => scheme.primary,
          _StageState.upcoming => scheme.surfaceContainerHighest,
        },
        shape: BoxShape.circle,
      ),
      child: Center(child: child),
    );
  }
}

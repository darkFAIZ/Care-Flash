import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../domain/entities/active_session.dart';
import '../bloc/active_session_bloc.dart';
import '../widgets/hold_to_activate_sos_button.dart';

class ActiveSessionScreen extends StatefulWidget {
  final ActiveSession session;
  final VoidCallback onSessionFinished;

  const ActiveSessionScreen({
    super.key,
    required this.session,
    required this.onSessionFinished,
  });

  @override
  State<ActiveSessionScreen> createState() => _ActiveSessionScreenState();
}

class _ActiveSessionScreenState extends State<ActiveSessionScreen> {
  @override
  void initState() {
    super.initState();
    context
        .read<ActiveSessionBloc>()
        .add(StartActiveSession(widget.session));
  }

  String _formatDuration(int seconds) {
    final int hours = seconds ~/ 3600;
    final int minutes = (seconds % 3600) ~/ 60;
    final int remainingSeconds = seconds % 60;
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ActiveSessionBloc, ActiveSessionState>(
      listener: (context, state) {
        if (state is ActiveSessionCompleted) {
          _showCompletionDialog(
            title: 'Session Successfully Completed',
            message:
                'You completed the care session. 100% base earnings have been credited to your balance.',
            payout: state.finalEarningsIdr,
            icon: Icons.check_circle,
            color: AppColors.safetyGreen,
          );
        } else if (state is ActiveSessionEarlyEnded) {
          _showCompletionDialog(
            title: 'Early Termination by Care Seeker',
            message:
                'Care seeker ended the assignment early. As per the 50% early termination rule, you are awarded 50% compensation.',
            payout: state.compensationEarningsIdr,
            icon: Icons.info_outline,
            color: AppColors.warningAmber,
          );
        } else if (state is ActiveSessionSosTriggered) {
          _showCompletionDialog(
            title: 'Emergency SOS Triggered',
            message:
                'Emergency response dispatched to location. Platform safety team is actively monitoring. Caregiver compensation is 100% protected.',
            payout: state.protectedEarningsIdr,
            icon: Icons.warning_rounded,
            color: AppColors.emergencyRed,
          );
        }
      },
      builder: (context, state) {
        final currentSession = state is ActiveSessionRunning
            ? state.session
            : widget.session;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Active Care Session'),
            automaticallyImplyLeading: false,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Seeker Banner
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Assisting Care Seeker',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondaryLight),
                            ),
                            Text(
                              currentSession.careSeekerName,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Chip(
                          label: Text(
                            CurrencyFormatter.toIdr(
                                currentSession.basePayoutIdr),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          backgroundColor:
                              AppColors.primaryGreen.withAlpha(20),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Countdown HUD
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 28),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'REMAINING SESSION TIME',
                        style: TextStyle(
                          fontSize: 12,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textSecondaryLight,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _formatDuration(currentSession.remainingSeconds),
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                          color: AppColors.primaryGreen,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Boundaries Checklist
                const Text(
                  'Agreed Safety Boundaries',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                ...currentSession.boundaries.map(
                  (b) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: CheckboxListTile(
                      value: b.isAcknowledged,
                      onChanged: (_) {
                        context
                            .read<ActiveSessionBloc>()
                            .add(ToggleBoundary(b.id));
                      },
                      title: Text(
                        b.title,
                        style: TextStyle(
                          fontSize: 14,
                          decoration: b.isAcknowledged
                              ? TextDecoration.lineThrough
                              : null,
                          color: b.isAcknowledged
                              ? AppColors.textSecondaryLight
                              : AppColors.textPrimaryLight,
                        ),
                      ),
                      activeColor: AppColors.safetyGreen,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Complete Session Button
                ElevatedButton.icon(
                  onPressed: () {
                    context
                        .read<ActiveSessionBloc>()
                        .add(const CompleteSessionRequested());
                  },
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Mark Work Completed'),
                ),
                const SizedBox(height: 12),

                // Early Termination simulation button for demo
                OutlinedButton.icon(
                  onPressed: () {
                    context
                        .read<ActiveSessionBloc>()
                        .add(const SeekerEarlyEndReceived());
                  },
                  icon: const Icon(Icons.cancel_outlined),
                  label: const Text('Demo: Seeker Ends Session Early (50% Rule)'),
                ),
                const SizedBox(height: 28),

                // SOS Hold To Activate Button
                HoldToActivateSosButton(
                  onSosTriggered: () {
                    context
                        .read<ActiveSessionBloc>()
                        .add(const SosEmergencyTriggered());
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showCompletionDialog({
    required String title,
    required String message,
    required int payout,
    required IconData icon,
    required Color color,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withAlpha(20),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Credited Compensation:'),
                  Text(
                    CurrencyFormatter.toIdr(payout),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              widget.onSessionFinished();
            },
            child: const Text('Return to Home'),
          ),
        ],
      ),
    );
  }
}

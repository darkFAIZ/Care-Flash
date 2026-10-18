import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../domain/entities/request_offer.dart';

class IncomingOfferDialog extends StatelessWidget {
  final RequestOffer offer;
  final int secondsRemaining;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const IncomingOfferDialog({
    super.key,
    required this.offer,
    required this.secondsRemaining,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    final double progress = (secondsRemaining / 30.0).clamp(0.0, 1.0);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Bar with Timer & Reference
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Chip(
                  label: Text(
                    offer.requestReference,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  backgroundColor: AppColors.primaryGreen.withAlpha(20),
                ),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 44,
                      height: 44,
                      child: CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 4,
                        color: secondsRemaining <= 5
                            ? AppColors.emergencyRed
                            : AppColors.safetyGreen,
                        backgroundColor: AppColors.borderLight,
                      ),
                    ),
                    Text(
                      '$secondsRemaining',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: secondsRemaining <= 5
                            ? AppColors.emergencyRed
                            : AppColors.textPrimaryLight,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Help Type Title
            Text(
              offer.helpType,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (offer.description != null) ...[
              const SizedBox(height: 6),
              Text(
                offer.description!,
                style: const TextStyle(
                  color: AppColors.textSecondaryLight,
                  fontSize: 14,
                ),
              ),
            ],
            const SizedBox(height: 16),

            // Duration & Payout Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.safetyGreen.withAlpha(25),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Expected Earnings',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                      ),
                      Text(
                        CurrencyFormatter.toIdr(offer.expectedEarningsIdr),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryGreen,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const Icon(Icons.timer_outlined, size: 18, color: AppColors.primaryGreen),
                      const SizedBox(width: 4),
                      Text(
                        '${offer.durationMinutes} min',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Boundary Checklist preview
            if (offer.boundaryChecklist.isNotEmpty) ...[
              const Text(
                'Care Boundaries & Rules:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 6),
              ...offer.boundaryChecklist.map(
                (boundary) => Padding(
                  padding: const EdgeInsets.only(bottom: 4.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.check_circle_outline,
                          size: 16, color: AppColors.safetyGreen),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          boundary,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
            ],

            // Privacy Notice (FR-CM-8)
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blueGrey.withAlpha(20),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.shield, size: 20, color: Colors.blueGrey),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Privacy Notice: Exact destination and verification PIN are securely hidden until offer acceptance.',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.blueGrey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onDecline,
                    child: const Text('Decline'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onAccept,
                    child: const Text('Accept Offer'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

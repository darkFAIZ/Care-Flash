import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/caregiver_user.dart';
import '../bloc/auth_bloc.dart';

class VerificationStatusScreen extends StatelessWidget {
  final CaregiverProfile profile;

  const VerificationStatusScreen({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    final bool isApproved =
        profile.verificationStatus == VerificationStatus.approved;
    final bool hasBadge = profile.safetyBadgeEarned;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verification Status'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => context.read<AuthBloc>().add(const LogoutRequested()),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 16),
            CircleAvatar(
              radius: 48,
              backgroundColor: isApproved && hasBadge
                  ? AppColors.safetyGreen.withAlpha(50)
                  : AppColors.warningAmber.withAlpha(50),
              child: Icon(
                isApproved && hasBadge
                    ? Icons.verified_user
                    : Icons.pending_actions,
                size: 54,
                color: isApproved && hasBadge
                    ? AppColors.safetyGreen
                    : AppColors.warningAmber,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              profile.fullName,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            Text(
              profile.university,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondaryLight,
                  ),
            ),
            const SizedBox(height: 24),
            // Status Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildStatusRow(
                      context,
                      title: 'Student Identity Verification',
                      isComplete: isApproved,
                      statusText: isApproved ? 'Verified' : 'Under Review',
                    ),
                    const Divider(height: 24),
                    _buildStatusRow(
                      context,
                      title: 'Care-Flash Safety Badge',
                      isComplete: hasBadge,
                      statusText: hasBadge ? 'Certified' : 'Required',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (!hasBadge) ...[
              Card(
                color: AppColors.safetyGreen.withAlpha(20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: AppColors.safetyGreen),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.shield_outlined,
                              color: AppColors.safetyGreen),
                          SizedBox(width: 8),
                          Text(
                            'Safety Certification Required',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryGreen,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'To unlock availability and start accepting care assignments, all student caregivers must complete the verified safety and boundaries training.',
                        style: TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            context
                                .read<AuthBloc>()
                                .add(const SafetyModuleCompleted());
                          },
                          icon: const Icon(Icons.school),
                          label: const Text('Complete Safety Training'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            if (!isApproved)
              const Text(
                'Identity document verification typically takes 12-24 hours. Our trust & safety team validates student credentials with your university portal.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textSecondaryLight,
                  fontSize: 13,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(
    BuildContext context, {
    required String title,
    required bool isComplete,
    required String statusText,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          ),
        ),
        Row(
          children: [
            Icon(
              isComplete ? Icons.check_circle : Icons.hourglass_top,
              color: isComplete ? AppColors.safetyGreen : AppColors.warningAmber,
              size: 20,
            ),
            const SizedBox(width: 6),
            Text(
              statusText,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color:
                    isComplete ? AppColors.safetyGreen : AppColors.warningAmber,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

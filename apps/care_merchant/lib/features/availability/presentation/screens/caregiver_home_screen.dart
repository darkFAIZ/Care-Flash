import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../auth_onboarding/presentation/bloc/auth_bloc.dart';
import '../../../matching/presentation/bloc/matching_bloc.dart';
import '../bloc/availability_bloc.dart';

class CaregiverHomeScreen extends StatelessWidget {
  const CaregiverHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AvailabilityBloc, AvailabilityState>(
      listener: (context, state) {
        if (state is AvailabilityLoaded && state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: AppColors.emergencyRed,
            ),
          );
        }
      },
      builder: (context, state) {
        if (state is! AvailabilityLoaded) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final profile = state.profile;
        final isAvailable = state.isAvailable;

        return Scaffold(
          appBar: AppBar(
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Care-Merchant',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                if (profile.safetyBadgeEarned)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.safetyGreen.withAlpha(40),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.safetyGreen),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.verified,
                            color: AppColors.safetyGreen, size: 14),
                        SizedBox(width: 4),
                        Text(
                          'VERIFIED',
                          style: TextStyle(
                            color: AppColors.safetyGreen,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () =>
                    context.read<AuthBloc>().add(const LogoutRequested()),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Profile & Rating Summary Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: AppColors.primaryGreen.withAlpha(30),
                          child: Text(
                            profile.fullName.isNotEmpty
                                ? profile.fullName[0]
                                : 'C',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryGreen,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                profile.fullName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              Text(
                                profile.university,
                                style: const TextStyle(
                                  color: AppColors.textSecondaryLight,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(Icons.star,
                                      color: Colors.amber, size: 16),
                                  const SizedBox(width: 4),
                                  Text(
                                    profile.averageRating.toStringAsFixed(2),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    '${profile.totalCompletedSessions} sessions',
                                    style: const TextStyle(
                                      color: AppColors.textSecondaryLight,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Availability Status Toggle Card
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: isAvailable
                          ? AppColors.safetyGreen
                          : AppColors.borderLight,
                      width: isAvailable ? 2 : 1,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isAvailable
                                      ? 'You are Online'
                                      : 'You are Offline',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  isAvailable
                                      ? 'Ready to accept care assignments'
                                      : 'Toggle switch to go online',
                                  style: const TextStyle(
                                    color: AppColors.textSecondaryLight,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                            Switch(
                              value: isAvailable,
                              activeColor: AppColors.safetyGreen,
                              onChanged: (val) {
                                context
                                    .read<AvailabilityBloc>()
                                    .add(ToggleAvailability(val));
                              },
                            ),
                          ],
                        ),
                        if (isAvailable) ...[
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.safetyGreen.withAlpha(25),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Row(
                              children: [
                                SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.safetyGreen,
                                  ),
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Listening for nearby emergency requests...',
                                    style: TextStyle(
                                      color: AppColors.primaryGreen,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Demo Simulation Controls
                if (isAvailable)
                  OutlinedButton.icon(
                    onPressed: () {
                      context
                          .read<MatchingBloc>()
                          .add(const TriggerSimulatedOffer());
                    },
                    icon: const Icon(Icons.flash_on),
                    label: const Text('Simulate Incoming Request'),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

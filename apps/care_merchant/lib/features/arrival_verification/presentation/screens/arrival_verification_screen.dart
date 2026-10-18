import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../ride_transit/domain/entities/grab_ride_info.dart';
import '../bloc/arrival_verification_bloc.dart';

class ArrivalVerificationScreen extends StatefulWidget {
  final AcceptedTrip trip;
  final VoidCallback onVerificationComplete;

  const ArrivalVerificationScreen({
    super.key,
    required this.trip,
    required this.onVerificationComplete,
  });

  @override
  State<ArrivalVerificationScreen> createState() =>
      _ArrivalVerificationScreenState();
}

class _ArrivalVerificationScreenState extends State<ArrivalVerificationScreen> {
  final _pinController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context
        .read<ArrivalVerificationBloc>()
        .add(InitializeArrival(widget.trip));
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ArrivalVerificationBloc, ArrivalVerificationState>(
      listener: (context, state) {
        if (state is HandoverComplete) {
          widget.onVerificationComplete();
        }
      },
      builder: (context, state) {
        final isStage2 =
            state is Stage2AwaitingScan || state is HandoverComplete;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Arrival & Handover Verification'),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Stepper Header
                Row(
                  children: [
                    _buildStepIndicator(
                      step: 1,
                      title: 'Client PIN',
                      isActive: !isStage2,
                      isDone: isStage2,
                    ),
                    const Expanded(child: Divider(thickness: 2)),
                    _buildStepIndicator(
                      step: 2,
                      title: 'Safety Button QR',
                      isActive: isStage2,
                      isDone: state is HandoverComplete,
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Seeker and Destination Info Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Care Seeker: ${widget.trip.careSeekerName}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.trip.destinationAddress,
                          style: const TextStyle(
                            color: AppColors.textSecondaryLight,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                if (!isStage2) ...[
                  // STAGE 1: PIN Input
                  const Text(
                    'Step 1: Verify Seeker Code',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Ask the care seeker for their 6-digit verification code to confirm their identity before starting.',
                    style: TextStyle(
                      color: AppColors.textSecondaryLight,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _pinController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 24,
                      letterSpacing: 8,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: const InputDecoration(
                      hintText: '••••••',
                      counterText: '',
                    ),
                  ),
                  if (state is Stage1AwaitingCode &&
                      state.errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      state.errorMessage!,
                      style: const TextStyle(
                        color: AppColors.emergencyRed,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: state is Stage1AwaitingCode && state.isVerifying
                        ? null
                        : () {
                            context.read<ArrivalVerificationBloc>().add(
                                  VerifyClientCodeSubmitted(
                                    _pinController.text.trim(),
                                  ),
                                );
                          },
                    child: state is Stage1AwaitingCode && state.isVerifying
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text('Verify Seeker PIN'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () {
                      _pinController.text = '123456';
                    },
                    child: const Text('Autofill Valid Demo PIN (123456)'),
                  ),
                ] else ...[
                  // STAGE 2: QR & NFC Activation
                  const Text(
                    'Step 2: Safety Button Handover',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Hand the physical Care-Flash Safety Button to the care seeker. Present this QR code or tap the NFC tag to pair the hardware button to this booking.',
                    style: TextStyle(
                      color: AppColors.textSecondaryLight,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: AppColors.safetyGreen, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(20),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.qr_code_2,
                            size: 130,
                            color: Colors.black87,
                          ),
                          Text(
                            (state as Stage2AwaitingScan).payload.buttonToken,
                            style: const TextStyle(
                              fontSize: 11,
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
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
                            'Awaiting care seeker scan confirmation...',
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
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () {
                      context
                          .read<ArrivalVerificationBloc>()
                          .add(const SimulateSeekerScan());
                    },
                    icon: const Icon(Icons.check_circle),
                    label: const Text('Simulate Seeker Button Scan'),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStepIndicator({
    required int step,
    required String title,
    required bool isActive,
    required bool isDone,
  }) {
    return Row(
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: isDone
              ? AppColors.safetyGreen
              : isActive
                  ? AppColors.primaryGreen
                  : AppColors.borderLight,
          child: isDone
              ? const Icon(Icons.check, size: 16, color: Colors.white)
              : Text(
                  '$step',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isActive ? Colors.white : AppColors.textSecondaryLight,
                  ),
                ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontWeight: isActive || isDone ? FontWeight.bold : FontWeight.normal,
            color: isActive || isDone
                ? AppColors.textPrimaryLight
                : AppColors.textSecondaryLight,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

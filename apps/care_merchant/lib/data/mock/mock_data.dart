import '../../features/auth_onboarding/domain/entities/caregiver_user.dart';
import '../../features/matching/domain/entities/request_offer.dart';
import '../../features/ride_transit/domain/entities/grab_ride_info.dart';
import '../../features/earnings/domain/entities/earnings_ledger.dart';

class MockData {
  static const CaregiverProfile verifiedCaregiver = CaregiverProfile(
    id: 'cg_001',
    fullName: 'Alya Putri',
    email: 'alya.putri@ui.ac.id',
    university: 'Universitas Indonesia',
    studentIdNumber: '2106728192',
    studentCardPhotoUrl: 'https://storage.careflash.id/ktm/2106728192.jpg',
    verificationStatus: VerificationStatus.approved,
    safetyBadgeEarned: true,
    gender: CaregiverGender.female,
    isAvailable: true,
    averageRating: 4.95,
    totalCompletedSessions: 28,
  );

  static const CaregiverProfile pendingCaregiver = CaregiverProfile(
    id: 'cg_002',
    fullName: 'Budi Santoso',
    email: 'budi.santoso@itb.ac.id',
    university: 'Institut Teknologi Bandung',
    studentIdNumber: '13521098',
    verificationStatus: VerificationStatus.pending,
    safetyBadgeEarned: false,
    gender: CaregiverGender.male,
    isAvailable: false,
    averageRating: 5.0,
    totalCompletedSessions: 0,
  );

  static RequestOffer sampleOffer({Duration validity = const Duration(seconds: 30)}) {
    return RequestOffer(
      requestReference: 'CR-2026-9812',
      helpType: 'Elderly Mobility & Companionship',
      description: 'Need assistance accompanying my grandmother for a light park stroll.',
      boundaryChecklist: const [
        'Light walking support',
        'No heavy lifting exceeding 15kg',
        'No administering prescription medication',
      ],
      durationMinutes: 60,
      expectedEarningsIdr: 50000,
      expiresAt: DateTime.now().add(validity),
    );
  }

  static const GrabRideInfo sampleGrabRide = GrabRideInfo(
    rideId: 'GRAB-8819',
    driverName: 'Pak Joko (GrabCar)',
    vehiclePlate: 'B 1928 KFL',
    vehicleModel: 'Toyota Avanza Silver',
    driverPhone: '+6281234567890',
    etaMinutes: 4,
    stage: GrabRideStage.driverAssigned,
  );

  static const AcceptedTrip sampleAcceptedTrip = AcceptedTrip(
    bookingId: 'BK-9812',
    requestReference: 'CR-2026-9812',
    careSeekerName: 'Ibu Ratna',
    destinationAddress: 'Jl. HOS Cokroaminoto No. 12, Menteng, Jakarta Pusat',
    latitude: -6.1950,
    longitude: 106.8320,
    durationMinutes: 60,
    payoutIdr: 50000,
    boundaryChecklist: [
      'Light walking support',
      'No heavy lifting exceeding 15kg',
      'No administering prescription medication',
    ],
    grabRide: sampleGrabRide,
  );

  static EarningsLedger sampleEarnings = EarningsLedger(
    availableBalanceIdr: 375000,
    pendingBalanceIdr: 50000,
    lifetimeEarningsIdr: 1250000,
    transactions: [
      TransactionRecord(
        id: 'TX-101',
        bookingReference: 'CR-2026-9750',
        timestamp: DateTime.now().subtract(const Duration(hours: 3)),
        amountIdr: 50000,
        description: 'Completed 60m Mobility Session',
        status: 'settled',
      ),
      TransactionRecord(
        id: 'TX-100',
        bookingReference: 'CR-2026-9630',
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
        amountIdr: 75000,
        description: 'Completed 90m Companionship Session',
        status: 'settled',
      ),
      TransactionRecord(
        id: 'TX-099',
        bookingReference: 'WD-0012',
        timestamp: DateTime.now().subtract(const Duration(days: 3)),
        amountIdr: -200000,
        description: 'Bank Transfer Withdrawal (BCA)',
        status: 'withdrawn',
      ),
    ],
  );
}

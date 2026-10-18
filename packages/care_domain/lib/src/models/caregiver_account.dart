import '../enums.dart';
import 'account.dart';

/// A caregiver's account including its onboarding state. (FR-CM-1 to FR-CM-6)
///
/// Care-Merchant works with this type. Care-Flash only ever sees the public
/// [Caregiver] profile produced by [toPublic], so student identity details stay
/// private to the caregiver app. (DC-CM-3)
class CaregiverAccount {
  const CaregiverAccount({
    required this.id,
    required this.name,
    required this.email,
    required this.gender,
    this.rating = 0,
    this.reviewCount = 0,
    this.verificationStatus = VerificationStatus.notSubmitted,
    this.rejectionReason,
    this.safetyModuleCompleted = false,
    this.availability = CaregiverAvailability.available,
    this.studentIdNumber,
    this.university,
    this.studentIdDocumentLabel,
    this.verificationSubmittedAt,
  });

  final String id;
  final String name;
  final String email;

  /// Recorded for the care seeker's gender matching filter. (FR-CM-5)
  final Gender gender;

  final double rating;
  final int reviewCount;

  /// Platform review state for the submitted student identity. (FR-CM-2, FR-CM-3)
  final VerificationStatus verificationStatus;

  /// Why the platform rejected the submission, when [verificationStatus] is
  /// [VerificationStatus.rejected]. (FR-CM-3)
  final String? rejectionReason;

  /// True once the caregiver completed the safety module and earned the badge.
  /// (FR-CM-4)
  final bool safetyModuleCompleted;

  final CaregiverAvailability availability;

  // Onboarding details the caregiver submitted. (FR-CM-2)
  final String? studentIdNumber;
  final String? university;
  final String? studentIdDocumentLabel;
  final DateTime? verificationSubmittedAt;

  String get firstName => name.split(' ').first;

  /// A short line such as `4.8 (126 reviews)`.
  String get ratingLabel =>
      '${rating.toStringAsFixed(1)} ($reviewCount review${reviewCount == 1 ? '' : 's'})';

  bool get isVerified => verificationStatus == VerificationStatus.approved;

  bool get canResubmit =>
      verificationStatus == VerificationStatus.rejected ||
      verificationStatus == VerificationStatus.notSubmitted;

  /// True when the caregiver may be offered incoming requests. Requests also
  /// require availability, so all three conditions are checked together.
  /// (FR-CM-7)
  bool get canReceiveRequests =>
      isVerified &&
      safetyModuleCompleted &&
      availability == CaregiverAvailability.available;

  /// The public profile shown to a care seeker once matched. Onboarding details
  /// are deliberately left off. (FR-P-7)
  Caregiver toPublic() => Caregiver(
        id: id,
        name: name,
        gender: gender,
        rating: rating,
        reviewCount: reviewCount,
        studentVerified: isVerified,
        safetyBadge: safetyModuleCompleted,
        availability: availability,
      );

  static const Object _unset = Object();

  CaregiverAccount copyWith({
    String? name,
    Gender? gender,
    double? rating,
    int? reviewCount,
    VerificationStatus? verificationStatus,
    Object? rejectionReason = _unset,
    bool? safetyModuleCompleted,
    CaregiverAvailability? availability,
    Object? studentIdNumber = _unset,
    Object? university = _unset,
    Object? studentIdDocumentLabel = _unset,
    Object? verificationSubmittedAt = _unset,
  }) {
    return CaregiverAccount(
      id: id,
      name: name ?? this.name,
      email: email,
      gender: gender ?? this.gender,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      rejectionReason: rejectionReason == _unset
          ? this.rejectionReason
          : rejectionReason as String?,
      safetyModuleCompleted: safetyModuleCompleted ?? this.safetyModuleCompleted,
      availability: availability ?? this.availability,
      studentIdNumber: studentIdNumber == _unset
          ? this.studentIdNumber
          : studentIdNumber as String?,
      university: university == _unset ? this.university : university as String?,
      studentIdDocumentLabel: studentIdDocumentLabel == _unset
          ? this.studentIdDocumentLabel
          : studentIdDocumentLabel as String?,
      verificationSubmittedAt: verificationSubmittedAt == _unset
          ? this.verificationSubmittedAt
          : verificationSubmittedAt as DateTime?,
    );
  }

  Map<String, Object?> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'gender': gender.name,
        'rating': rating,
        'reviewCount': reviewCount,
        'verificationStatus': verificationStatus.name,
        'rejectionReason': rejectionReason,
        'safetyModuleCompleted': safetyModuleCompleted,
        'availability': availability.name,
        'studentIdNumber': studentIdNumber,
        'university': university,
        'studentIdDocumentLabel': studentIdDocumentLabel,
        'verificationSubmittedAt': verificationSubmittedAt?.toIso8601String(),
      };

  factory CaregiverAccount.fromJson(Map<String, Object?> json) => CaregiverAccount(
        id: json['id']! as String,
        name: json['name']! as String,
        email: json['email']! as String,
        gender: Gender.values.byName(json['gender']! as String),
        rating: (json['rating'] as num?)?.toDouble() ?? 0,
        reviewCount: json['reviewCount'] as int? ?? 0,
        verificationStatus: VerificationStatus.values
            .byName(json['verificationStatus'] as String? ?? 'notSubmitted'),
        rejectionReason: json['rejectionReason'] as String?,
        safetyModuleCompleted: json['safetyModuleCompleted'] as bool? ?? false,
        availability: CaregiverAvailability.values
            .byName(json['availability'] as String? ?? 'available'),
        studentIdNumber: json['studentIdNumber'] as String?,
        university: json['university'] as String?,
        studentIdDocumentLabel: json['studentIdDocumentLabel'] as String?,
        verificationSubmittedAt: json['verificationSubmittedAt'] == null
            ? null
            : DateTime.parse(json['verificationSubmittedAt']! as String),
      );
}

/// Result of a caregiver sign-in or sign-up attempt. (FR-CM-1)
class CaregiverAuthResult {
  const CaregiverAuthResult.success(this.user)
      : success = true,
        errorMessage = null;

  const CaregiverAuthResult.failure(this.errorMessage)
      : success = false,
        user = null;

  final bool success;
  final CaregiverAccount? user;
  final String? errorMessage;
}

import 'package:equatable/equatable.dart';

enum VerificationStatus { pending, approved, rejected }

enum CaregiverGender { male, female }

class CaregiverProfile extends Equatable {
  final String id;
  final String fullName;
  final String email;
  final String university;
  final String studentIdNumber;
  final String? studentCardPhotoUrl;
  final VerificationStatus verificationStatus;
  final String? rejectionReason;
  final bool safetyBadgeEarned;
  final CaregiverGender gender;
  final bool isAvailable;
  final double averageRating;
  final int totalCompletedSessions;

  const CaregiverProfile({
    required this.id,
    required this.fullName,
    required this.email,
    required this.university,
    required this.studentIdNumber,
    this.studentCardPhotoUrl,
    required this.verificationStatus,
    this.rejectionReason,
    required this.safetyBadgeEarned,
    required this.gender,
    required this.isAvailable,
    this.averageRating = 5.0,
    this.totalCompletedSessions = 0,
  });

  CaregiverProfile copyWith({
    String? id,
    String? fullName,
    String? email,
    String? university,
    String? studentIdNumber,
    String? studentCardPhotoUrl,
    VerificationStatus? verificationStatus,
    String? rejectionReason,
    bool? safetyBadgeEarned,
    CaregiverGender? gender,
    bool? isAvailable,
    double? averageRating,
    int? totalCompletedSessions,
  }) {
    return CaregiverProfile(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      university: university ?? this.university,
      studentIdNumber: studentIdNumber ?? this.studentIdNumber,
      studentCardPhotoUrl: studentCardPhotoUrl ?? this.studentCardPhotoUrl,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      safetyBadgeEarned: safetyBadgeEarned ?? this.safetyBadgeEarned,
      gender: gender ?? this.gender,
      isAvailable: isAvailable ?? this.isAvailable,
      averageRating: averageRating ?? this.averageRating,
      totalCompletedSessions:
          totalCompletedSessions ?? this.totalCompletedSessions,
    );
  }

  @override
  List<Object?> get props => [
        id,
        fullName,
        email,
        university,
        studentIdNumber,
        studentCardPhotoUrl,
        verificationStatus,
        rejectionReason,
        safetyBadgeEarned,
        gender,
        isAvailable,
        averageRating,
        totalCompletedSessions,
      ];
}

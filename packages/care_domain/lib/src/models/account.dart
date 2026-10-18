import '../enums.dart';

/// A care seeker account (Care-Flash user). (FR-CS-1)
class CareSeeker {
  const CareSeeker({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
  });

  final String id;
  final String name;
  final String email;
  final String? phone;

  CareSeeker copyWith({String? name, String? email, String? phone}) {
    return CareSeeker(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
    );
  }

  Map<String, Object?> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'phone': phone,
      };

  factory CareSeeker.fromJson(Map<String, Object?> json) => CareSeeker(
        id: json['id']! as String,
        name: json['name']! as String,
        email: json['email']! as String,
        phone: json['phone'] as String?,
      );
}

/// A verified student caregiver (Care-Merchant user).
///
/// Only the fields both apps need are kept here. Bio/profile extras were
/// explicitly left out of scope (AGENTS.md §3).
class Caregiver {
  const Caregiver({
    required this.id,
    required this.name,
    required this.gender,
    this.rating = 0,
    this.reviewCount = 0,
    this.studentVerified = true,
    this.safetyBadge = true,
    this.availability = CaregiverAvailability.available,
  });

  final String id;
  final String name;
  final Gender gender;
  final double rating;
  final int reviewCount;

  /// True when the platform verified the caregiver's student identity. (FR-P-2)
  final bool studentVerified;

  /// True after the caregiver completed the safety module. (FR-P-2, FR-CM-4)
  final bool safetyBadge;

  final CaregiverAvailability availability;

  String get firstName => name.split(' ').first;

  /// A short line such as `4.8 (126 reviews)`.
  String get ratingLabel =>
      '${rating.toStringAsFixed(1)} ($reviewCount review${reviewCount == 1 ? '' : 's'})';

  Caregiver copyWith({
    String? name,
    Gender? gender,
    double? rating,
    int? reviewCount,
    bool? studentVerified,
    bool? safetyBadge,
    CaregiverAvailability? availability,
  }) {
    return Caregiver(
      id: id,
      name: name ?? this.name,
      gender: gender ?? this.gender,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      studentVerified: studentVerified ?? this.studentVerified,
      safetyBadge: safetyBadge ?? this.safetyBadge,
      availability: availability ?? this.availability,
    );
  }

  Map<String, Object?> toJson() => {
        'id': id,
        'name': name,
        'gender': gender.name,
        'rating': rating,
        'reviewCount': reviewCount,
        'studentVerified': studentVerified,
        'safetyBadge': safetyBadge,
        'availability': availability.name,
      };

  factory Caregiver.fromJson(Map<String, Object?> json) => Caregiver(
        id: json['id']! as String,
        name: json['name']! as String,
        gender: Gender.values.byName(json['gender']! as String),
        rating: (json['rating'] as num?)?.toDouble() ?? 0,
        reviewCount: json['reviewCount'] as int? ?? 0,
        studentVerified: json['studentVerified'] as bool? ?? true,
        safetyBadge: json['safetyBadge'] as bool? ?? true,
        availability:
            CaregiverAvailability.values.byName(json['availability'] as String? ?? 'available'),
      );
}

/// Result of a sign-in or sign-up attempt. (FR-CS-1)
class AuthResult {
  const AuthResult.success(this.user)
      : success = true,
        errorMessage = null;

  const AuthResult.failure(this.errorMessage)
      : success = false,
        user = null;

  final bool success;
  final CareSeeker? user;
  final String? errorMessage;
}

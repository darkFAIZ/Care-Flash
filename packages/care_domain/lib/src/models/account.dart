import '../enums.dart';

/// A care seeker account (Care-Flash user). (FR-CS-1)
class CareSeeker {
  const CareSeeker({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.avatarDataUrl,
  });

  final String id;
  final String name;
  final String email;
  final String? phone;

  /// Optional profile photo as a `data:image/...;base64,...` string. Stored
  /// this way so the demo needs no file server. TODO(team): replace with an
  /// upload URL when the real API exists.
  final String? avatarDataUrl;

  static const Object _unset = Object();

  CareSeeker copyWith({
    String? name,
    String? email,
    Object? phone = _unset,
    Object? avatarDataUrl = _unset,
  }) {
    return CareSeeker(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone == _unset ? this.phone : phone as String?,
      avatarDataUrl:
          avatarDataUrl == _unset ? this.avatarDataUrl : avatarDataUrl as String?,
    );
  }

  Map<String, Object?> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'phone': phone,
        'avatarDataUrl': avatarDataUrl,
      };

  factory CareSeeker.fromJson(Map<String, Object?> json) => CareSeeker(
        id: json['id']! as String,
        name: json['name']! as String,
        email: json['email']! as String,
        phone: json['phone'] as String?,
        avatarDataUrl: json['avatarDataUrl'] as String?,
      );
}

/// A verified caregiver (Care-Merchant user).
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
    this.identityVerified = true,
    this.safetyBadge = true,
    this.availability = CaregiverAvailability.available,
    this.avatarDataUrl,
  });

  final String id;
  final String name;
  final Gender gender;
  final double rating;
  final int reviewCount;

  /// True when the platform verified the caregiver's KTP identity. (FR-P-2)
  final bool identityVerified;

  /// True after the caregiver completed the safety module. (FR-P-2, FR-CM-4)
  final bool safetyBadge;

  final CaregiverAvailability availability;

  /// Optional profile photo as a data URL. Shown on the matched-caregiver card.
  final String? avatarDataUrl;

  String get firstName => name.split(' ').first;

  /// A short line such as `4.8 (126 reviews)`.
  String get ratingLabel =>
      '${rating.toStringAsFixed(1)} ($reviewCount review${reviewCount == 1 ? '' : 's'})';

  Caregiver copyWith({
    String? name,
    Gender? gender,
    double? rating,
    int? reviewCount,
    bool? identityVerified,
    bool? safetyBadge,
    CaregiverAvailability? availability,
  }) {
    return Caregiver(
      id: id,
      name: name ?? this.name,
      gender: gender ?? this.gender,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      identityVerified: identityVerified ?? this.identityVerified,
      safetyBadge: safetyBadge ?? this.safetyBadge,
      availability: availability ?? this.availability,
      avatarDataUrl: avatarDataUrl,
    );
  }

  Map<String, Object?> toJson() => {
        'id': id,
        'name': name,
        'gender': gender.name,
        'rating': rating,
        'reviewCount': reviewCount,
        'identityVerified': identityVerified,
        'safetyBadge': safetyBadge,
        'availability': availability.name,
        'avatarDataUrl': avatarDataUrl,
      };

  factory Caregiver.fromJson(Map<String, Object?> json) => Caregiver(
        id: json['id']! as String,
        name: json['name']! as String,
        gender: Gender.values.byName(json['gender']! as String),
        rating: (json['rating'] as num?)?.toDouble() ?? 0,
        reviewCount: json['reviewCount'] as int? ?? 0,
        // `studentVerified` is the pre-KTP key, kept so saved demo data loads.
        identityVerified: json['identityVerified'] as bool? ??
            json['studentVerified'] as bool? ??
            true,
        safetyBadge: json['safetyBadge'] as bool? ?? true,
        availability:
            CaregiverAvailability.values.byName(json['availability'] as String? ?? 'available'),
        avatarDataUrl: json['avatarDataUrl'] as String?,
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

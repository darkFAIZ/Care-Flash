/// Feedback and ratings submitted after a session.
///
/// Caregiver feedback is kept separate from app feedback. (FR-CS-19, FR-CS-20,
/// FR-P-28)
library;

/// A rating and optional comment about the caregiver. (FR-CS-19)
class CaregiverRating {
  const CaregiverRating({
    required this.bookingId,
    required this.caregiverId,
    required this.stars,
    this.comment,
  }) : assert(stars >= 1 && stars <= 5, 'stars must be between 1 and 5');

  final String bookingId;
  final String caregiverId;
  final int stars;
  final String? comment;

  Map<String, Object?> toJson() => {
        'bookingId': bookingId,
        'caregiverId': caregiverId,
        'stars': stars,
        'comment': comment,
      };

  factory CaregiverRating.fromJson(Map<String, Object?> json) => CaregiverRating(
        bookingId: json['bookingId']! as String,
        caregiverId: json['caregiverId']! as String,
        stars: json['stars']! as int,
        comment: json['comment'] as String?,
      );
}

/// A rating and optional comment the caregiver leaves about the care seeker
/// after a session. (FR-CM-24)
///
/// The care seeker is identified only by the non-secret request reference;
/// the caregiver never learns their name or contact details. (FR-P-7)
class CareSeekerRating {
  const CareSeekerRating({
    required this.bookingId,
    required this.reference,
    required this.stars,
    this.comment,
  }) : assert(stars >= 1 && stars <= 5, 'stars must be between 1 and 5');

  final String bookingId;

  /// Non-secret request reference shown to the caregiver before accepting.
  final String reference;
  final int stars;
  final String? comment;

  Map<String, Object?> toJson() => {
        'bookingId': bookingId,
        'reference': reference,
        'stars': stars,
        'comment': comment,
      };

  factory CareSeekerRating.fromJson(Map<String, Object?> json) =>
      CareSeekerRating(
        bookingId: json['bookingId']! as String,
        reference: json['reference']! as String,
        stars: json['stars']! as int,
        comment: json['comment'] as String?,
      );
}

/// Feedback a care seeker left about a caregiver, surfaced to that caregiver
/// in Care-Merchant. (FR-CM-23, FR-P-27)
class FeedbackReceived {
  const FeedbackReceived({
    required this.bookingId,
    required this.reference,
    required this.stars,
    required this.receivedAt,
    this.comment,
  }) : assert(stars >= 1 && stars <= 5, 'stars must be between 1 and 5');

  final String bookingId;

  /// Non-secret request reference for the visit this feedback is about.
  final String reference;
  final int stars;
  final String? comment;
  final DateTime receivedAt;

  Map<String, Object?> toJson() => {
        'bookingId': bookingId,
        'reference': reference,
        'stars': stars,
        'comment': comment,
        'receivedAt': receivedAt.toIso8601String(),
      };

  factory FeedbackReceived.fromJson(Map<String, Object?> json) =>
      FeedbackReceived(
        bookingId: json['bookingId']! as String,
        reference: json['reference']! as String,
        stars: json['stars']! as int,
        comment: json['comment'] as String?,
        receivedAt: DateTime.parse(json['receivedAt']! as String),
      );
}

/// Feedback about the Care-Flash app itself. (FR-CS-20)
class AppFeedback {
  const AppFeedback({
    required this.stars,
    this.comment,
  }) : assert(stars >= 1 && stars <= 5, 'stars must be between 1 and 5');

  final int stars;
  final String? comment;

  Map<String, Object?> toJson() => {
        'stars': stars,
        'comment': comment,
      };

  factory AppFeedback.fromJson(Map<String, Object?> json) => AppFeedback(
        stars: json['stars']! as int,
        comment: json['comment'] as String?,
      );
}

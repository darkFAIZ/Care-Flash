import '../enums.dart';

/// A scan/read of the physical safety button handed to the care seeker.
/// (FR-CS-13, FR-CM-15, HI-1)
class ButtonVerification {
  const ButtonVerification({
    required this.method,
    required this.payload,
  });

  final ButtonVerificationMethod method;

  /// The identifier read from the booking-linked QR code or NFC tag.
  final String payload;
}

/// Result of verifying the safety button. (FR-CS-14, FR-CS-15)
class ButtonVerificationResult {
  const ButtonVerificationResult.success()
      : success = true,
        message = null;

  const ButtonVerificationResult.failed(this.message) : success = false;

  final bool success;
  final String? message;
}

/// A single piece of evidence attached to an incident report. (FR-CS-18)
///
/// TODO(team): evidence types, size limits and retention are undecided (SRS §4).
/// Keep this a simple list of attachments for now.
class EvidenceAttachment {
  const EvidenceAttachment({
    required this.id,
    required this.kind,
    required this.label,
    required this.addedAt,
  });

  final String id;
  final EvidenceKind kind;
  final String label;
  final DateTime addedAt;

  Map<String, Object?> toJson() => {
        'id': id,
        'kind': kind.name,
        'label': label,
        'addedAt': addedAt.toIso8601String(),
      };

  factory EvidenceAttachment.fromJson(Map<String, Object?> json) =>
      EvidenceAttachment(
        id: json['id']! as String,
        kind: EvidenceKind.values.byName(json['kind']! as String),
        label: json['label']! as String,
        addedAt: DateTime.parse(json['addedAt']! as String),
      );
}

/// An incident report submitted during or after a session. (FR-CS-18, FR-P-25)
class IncidentReport {
  const IncidentReport({
    required this.bookingId,
    required this.description,
    required this.createdAt,
    this.evidence = const [],
    this.fromPhysicalButton = false,
  });

  final String bookingId;
  final String description;
  final DateTime createdAt;
  final List<EvidenceAttachment> evidence;

  /// True when the physical safety button triggered the report. (HI-CS-2)
  final bool fromPhysicalButton;

  Map<String, Object?> toJson() => {
        'bookingId': bookingId,
        'description': description,
        'createdAt': createdAt.toIso8601String(),
        'evidence': evidence.map((item) => item.toJson()).toList(),
        'fromPhysicalButton': fromPhysicalButton,
      };

  factory IncidentReport.fromJson(Map<String, Object?> json) => IncidentReport(
        bookingId: json['bookingId']! as String,
        description: json['description']! as String,
        createdAt: DateTime.parse(json['createdAt']! as String),
        evidence: (json['evidence'] as List<Object?>? ?? const [])
            .map((item) => EvidenceAttachment.fromJson(item! as Map<String, Object?>))
            .toList(),
        fromPhysicalButton: json['fromPhysicalButton'] as bool? ?? false,
      );
}

import '../enums.dart';
import 'account.dart';
import 'boundary_checklist.dart';
import 'button_code.dart';
import 'location.dart';
import 'payment.dart';
import 'pricing.dart';

/// A status notification shown on the booking status screen. (FR-CS-21)
class BookingUpdate {
  const BookingUpdate({
    required this.status,
    required this.message,
    required this.at,
  });

  final BookingStatus status;
  final String message;
  final DateTime at;

  Map<String, Object?> toJson() => {
        'status': status.name,
        'message': message,
        'at': at.toIso8601String(),
      };

  factory BookingUpdate.fromJson(Map<String, Object?> json) => BookingUpdate(
        status: BookingStatus.values.byName(json['status']! as String),
        message: json['message']! as String,
        at: DateTime.parse(json['at']! as String),
      );
}

/// A paid care request and its full lifecycle.
///
/// This single model is shared by Care-Flash and Care-Merchant. Fields the
/// caregiver must not see before acceptance ([location] before confirmation and
/// [clientCode] before arrival) are documented where they are used. (FR-P-7)
class Booking {
  const Booking({
    required this.id,
    required this.requestReference,
    required this.helpType,
    this.description,
    required this.checklist,
    required this.location,
    required this.scheduledAt,
    required this.duration,
    required this.genderFilter,
    this.caregiver,
    this.price,
    this.estimatedGrabFare,
    this.actualGrabFare,
    this.paymentMethod,
    this.paymentStatus,
    this.refundAmount,
    this.caregiverPayout,
    this.clientCode,
    this.status = BookingStatus.draft,
    this.cancellationReason,
    this.buttonCode,
    this.outcome,
    required this.createdAt,
    this.updates = const [],
  });

  final String id;

  /// Non-secret reference the caregiver can see before accepting. (FR-P-7)
  final String requestReference;

  final HelpType helpType;
  final String? description;
  final BoundaryChecklist checklist;
  final VisitLocation location;
  final DateTime scheduledAt;
  final VisitDuration duration;
  final GenderFilter genderFilter;
  final Caregiver? caregiver;
  final PriceBreakdown? price;

  /// Estimated Grab fare for the caregiver's trip to the care seeker. (FR-P-10,
  /// FR-P-11)
  ///
  /// The care seeker pays this as part of the total. The caregiver never pays
  /// for the ride.
  final int? estimatedGrabFare;

  /// Grab fare actually charged, once known. It is usually the estimate, so it
  /// starts null. (FR-P-10)
  /// TODO(team): decide what happens when the real fare differs from the
  /// estimate. The SRS has not set a rule, so nothing is recomputed.
  final int? actualGrabFare;

  final PaymentMethod? paymentMethod;

  /// Status of the care seeker's payment for this booking, once it is paid.
  /// (FR-CS-11, FR-P-23)
  final PaymentStatus? paymentStatus;

  /// Amount returned to the care seeker, when a refund applies. A refund can be
  /// the full amount (report, no caregiver accepts) or a part of it (early
  /// end). (FR-CS-16, FR-P-13, FR-P-23)
  final int? refundAmount;

  /// Amount credited to the caregiver for this booking once it finishes:
  /// service earnings on completion, or compensation after an early end or SOS.
  /// (FR-P-21, FR-P-22, FR-P-24)
  final int? caregiverPayout;

  /// Private client verification code, generated after payment and shown only to
  /// the care seeker until presented at arrival. (FR-CS-12, FR-P-15)
  final String? clientCode;

  final BookingStatus status;
  final CancellationReason? cancellationReason;

  /// Booking-linked safety-button code, activated after the client code is
  /// verified and checked by the CARE SEEKER's scan. (HI-1, FR-P-17, FR-P-18)
  final ButtonCode? buttonCode;

  final SessionOutcome? outcome;
  final DateTime createdAt;
  final List<BookingUpdate> updates;

  /// The QR/NFC payload of the safety button, or `null` before it is
  /// activated. Kept for display and for the care seeker's scan.
  String? get safetyButtonId => buttonCode?.payload;

  /// Grab fare the care seeker actually pays for this booking: the real fare
  /// when known, otherwise the estimate. (FR-P-11)
  ///
  /// This is the amount the platform charges the care seeker; it is not part
  /// of the caregiver's earnings.
  int get effectiveGrabFare =>
      actualGrabFare ?? estimatedGrabFare ?? price?.grabFare ?? 0;

  /// Checks a scanned safety-button payload. Returns `null` when the platform
  /// accepts the scan, otherwise the reason the booking must be cancelled.
  /// (FR-P-18)
  ButtonCodeFailure? validateButtonPayload(String payload, {DateTime? now}) {
    final code = buttonCode;
    if (code == null) {
      return ButtonCodeFailure.noCode;
    }
    return code.validate(id, payload, now ?? DateTime.now());
  }

  int get durationMinutes => duration.minutes;

  /// True when the booking is ready to be paid. (FR-CS-11)
  bool get isPayable => status == BookingStatus.matched && price != null;

  /// True when the care seeker can show the client code. (FR-CS-12)
  bool get hasClientCode =>
      clientCode != null &&
      (status == BookingStatus.paidPending ||
          status == BookingStatus.confirmed ||
          status == BookingStatus.caregiverTravelling ||
          status == BookingStatus.arrived);

  /// True when the care seeker can scan the safety button. (FR-CS-13)
  bool get canVerifyButton =>
      status == BookingStatus.arrived || status == BookingStatus.codeVerified;

  /// True while the session is running, so Report and End Early are available.
  /// (FR-CS-16, FR-CS-17, UI-CS-2)
  bool get isSessionActive => status == BookingStatus.active;

  /// True once the care seeker has paid. A refunded payment was still paid.
  /// (FR-CS-11)
  bool get isPaid =>
      paymentStatus == PaymentStatus.succeeded ||
      paymentStatus == PaymentStatus.refunded ||
      paymentStatus == PaymentStatus.partiallyRefunded;

  /// True when the whole payment was returned to the care seeker. (FR-P-23)
  bool get isRefunded => paymentStatus == PaymentStatus.refunded;

  /// True when only part of the payment was returned. (FR-CS-16)
  bool get isPartiallyRefunded =>
      paymentStatus == PaymentStatus.partiallyRefunded;

  /// True when any amount was returned to the care seeker.
  bool get hasRefund => (refundAmount ?? 0) > 0;

  static const Object _unset = Object();

  Booking copyWith({
    String? requestReference,
    HelpType? helpType,
    String? description,
    BoundaryChecklist? checklist,
    VisitLocation? location,
    DateTime? scheduledAt,
    VisitDuration? duration,
    GenderFilter? genderFilter,
    Object? caregiver = _unset,
    Object? price = _unset,
    Object? estimatedGrabFare = _unset,
    Object? actualGrabFare = _unset,
    Object? paymentMethod = _unset,
    Object? paymentStatus = _unset,
    Object? refundAmount = _unset,
    Object? caregiverPayout = _unset,
    Object? clientCode = _unset,
    BookingStatus? status,
    Object? cancellationReason = _unset,
    Object? buttonCode = _unset,
    Object? outcome = _unset,
    List<BookingUpdate>? updates,
  }) {
    return Booking(
      id: id,
      requestReference: requestReference ?? this.requestReference,
      helpType: helpType ?? this.helpType,
      description: description ?? this.description,
      checklist: checklist ?? this.checklist,
      location: location ?? this.location,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      duration: duration ?? this.duration,
      genderFilter: genderFilter ?? this.genderFilter,
      caregiver: caregiver == _unset ? this.caregiver : caregiver as Caregiver?,
      price: price == _unset ? this.price : price as PriceBreakdown?,
      estimatedGrabFare: estimatedGrabFare == _unset
          ? this.estimatedGrabFare
          : estimatedGrabFare as int?,
      actualGrabFare:
          actualGrabFare == _unset ? this.actualGrabFare : actualGrabFare as int?,
      paymentMethod:
          paymentMethod == _unset ? this.paymentMethod : paymentMethod as PaymentMethod?,
      paymentStatus:
          paymentStatus == _unset ? this.paymentStatus : paymentStatus as PaymentStatus?,
      refundAmount:
          refundAmount == _unset ? this.refundAmount : refundAmount as int?,
      caregiverPayout:
          caregiverPayout == _unset ? this.caregiverPayout : caregiverPayout as int?,
      clientCode: clientCode == _unset ? this.clientCode : clientCode as String?,
      status: status ?? this.status,
      cancellationReason: cancellationReason == _unset
          ? this.cancellationReason
          : cancellationReason as CancellationReason?,
      buttonCode: buttonCode == _unset ? this.buttonCode : buttonCode as ButtonCode?,
      outcome: outcome == _unset ? this.outcome : outcome as SessionOutcome?,
      createdAt: createdAt,
      updates: updates ?? this.updates,
    );
  }

  /// Returns a copy with [update] appended, used for the notification feed.
  Booking withUpdate(BookingUpdate update) =>
      copyWith(updates: [...updates, update]);

  Map<String, Object?> toJson() => {
        'id': id,
        'requestReference': requestReference,
        'helpType': helpType.name,
        'description': description,
        'checklist': checklist.toJson(),
        'location': location.toJson(),
        'scheduledAt': scheduledAt.toIso8601String(),
        'duration': duration.name,
        'genderFilter': genderFilter.name,
        'caregiver': caregiver?.toJson(),
        'price': price?.toJson(),
        'estimatedGrabFare': estimatedGrabFare,
        'actualGrabFare': actualGrabFare,
        'paymentMethod': paymentMethod?.toJson(),
        'paymentStatus': paymentStatus?.name,
        'refundAmount': refundAmount,
        'caregiverPayout': caregiverPayout,
        'clientCode': clientCode,
        'status': status.name,
        'cancellationReason': cancellationReason?.name,
        'buttonCode': buttonCode?.toJson(),
        'outcome': outcome?.name,
        'createdAt': createdAt.toIso8601String(),
        'updates': updates.map((update) => update.toJson()).toList(),
      };

  factory Booking.fromJson(Map<String, Object?> json) {
    final caregiverJson = json['caregiver'];
    final priceJson = json['price'];
    final paymentMethodJson = json['paymentMethod'];
    final paymentStatus = json['paymentStatus'];
    final cancellationReason = json['cancellationReason'];
    final buttonCodeJson = json['buttonCode'];
    final outcome = json['outcome'];

    return Booking(
      id: json['id']! as String,
      requestReference: json['requestReference']! as String,
      helpType: HelpType.values.byName(json['helpType']! as String),
      description: json['description'] as String?,
      checklist: BoundaryChecklist.fromJson(
        json['checklist']! as Map<String, Object?>,
      ),
      location: VisitLocation.fromJson(json['location']! as Map<String, Object?>),
      scheduledAt: DateTime.parse(json['scheduledAt']! as String),
      duration: VisitDuration.values.byName(json['duration']! as String),
      genderFilter: GenderFilter.values.byName(json['genderFilter']! as String),
      caregiver: caregiverJson == null
          ? null
          : Caregiver.fromJson(caregiverJson as Map<String, Object?>),
      price: priceJson == null
          ? null
          : PriceBreakdown.fromJson(priceJson as Map<String, Object?>),
      estimatedGrabFare: json['estimatedGrabFare'] as int?,
      actualGrabFare: json['actualGrabFare'] as int?,
      paymentMethod: paymentMethodJson == null
          ? null
          : PaymentMethod.fromJson(paymentMethodJson as Map<String, Object?>),
      paymentStatus: paymentStatus == null
          ? null
          : PaymentStatus.values.byName(paymentStatus as String),
      refundAmount: json['refundAmount'] as int?,
      caregiverPayout: json['caregiverPayout'] as int?,
      clientCode: json['clientCode'] as String?,
      status: BookingStatus.values.byName(json['status']! as String),
      cancellationReason: cancellationReason == null
          ? null
          : CancellationReason.values.byName(cancellationReason as String),
      buttonCode: buttonCodeJson == null
          ? null
          : ButtonCode.fromJson(buttonCodeJson as Map<String, Object?>),
      outcome: outcome == null
          ? null
          : SessionOutcome.values.byName(outcome as String),
      createdAt: DateTime.parse(json['createdAt']! as String),
      updates: (json['updates'] as List<Object?>? ?? const [])
          .map((item) => BookingUpdate.fromJson(item! as Map<String, Object?>))
          .toList(),
    );
  }
}

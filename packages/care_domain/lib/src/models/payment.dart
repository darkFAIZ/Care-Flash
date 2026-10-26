import '../enums.dart';

/// A payment method available to the care seeker. (FR-CS-11)
///
/// Only a display label is kept. Card numbers and other card details are
/// handled by the payment provider and are never stored. (DC-CS-2)
class PaymentMethod {
  const PaymentMethod({
    required this.id,
    required this.type,
    required this.displayLabel,
  });

  final String id;
  final PaymentMethodType type;
  final String displayLabel;

  Map<String, Object?> toJson() => {
        'id': id,
        'type': type.name,
        'displayLabel': displayLabel,
      };

  factory PaymentMethod.fromJson(Map<String, Object?> json) => PaymentMethod(
        id: json['id']! as String,
        type: PaymentMethodType.values.byName(json['type']! as String),
        displayLabel: json['displayLabel']! as String,
      );
}

/// Result of a payment attempt. (FR-CS-11)
class PaymentResult {
  const PaymentResult.succeeded()
      : success = true,
        status = PaymentStatus.succeeded,
        message = null;

  const PaymentResult.failed([this.message])
      : success = false,
        status = PaymentStatus.failed;

  final bool success;
  final PaymentStatus status;
  final String? message;
}

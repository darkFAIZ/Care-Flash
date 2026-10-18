import '../enums.dart';

/// A single amount credited to a caregiver for a finished booking.
///
/// Service earnings on normal completion (FR-P-21), early-end compensation
/// (FR-P-22) and SOS compensation (FR-P-24) all arrive here, so one list feeds
/// the earnings screen, the transaction status and the session history.
/// (FR-CM-21)
class EarningEntry {
  const EarningEntry({
    required this.id,
    required this.bookingId,
    required this.reference,
    required this.kind,
    required this.amount,
    required this.at,
  });

  final String id;

  /// The booking this amount came from. (FR-CM-21)
  final String bookingId;

  /// The booking reference, shown as the session history line. (FR-CM-21)
  final String reference;

  final EarningKind kind;
  final int amount;
  final DateTime at;

  Map<String, Object?> toJson() => {
        'id': id,
        'bookingId': bookingId,
        'reference': reference,
        'kind': kind.name,
        'amount': amount,
        'at': at.toIso8601String(),
      };

  factory EarningEntry.fromJson(Map<String, Object?> json) => EarningEntry(
        id: json['id']! as String,
        bookingId: json['bookingId']! as String,
        reference: json['reference']! as String,
        kind: EarningKind.values.byName(json['kind']! as String),
        amount: json['amount']! as int,
        at: DateTime.parse(json['at']! as String),
      );
}

/// A caregiver request to move available earnings out of the platform.
/// (FR-CM-22, FR-P-29)
class Withdrawal {
  const Withdrawal({
    required this.id,
    required this.amount,
    required this.method,
    this.status = PayoutStatus.processing,
    required this.requestedAt,
  });

  final String id;
  final int amount;

  /// Payout method label; the supported methods are not decided yet.
  /// TODO(team): confirm the payout methods. (FR-CM-22, SRS open decision 6)
  final String method;

  final PayoutStatus status;
  final DateTime requestedAt;

  Map<String, Object?> toJson() => {
        'id': id,
        'amount': amount,
        'method': method,
        'status': status.name,
        'requestedAt': requestedAt.toIso8601String(),
      };

  factory Withdrawal.fromJson(Map<String, Object?> json) => Withdrawal(
        id: json['id']! as String,
        amount: json['amount']! as int,
        method: json['method']! as String,
        status: PayoutStatus.values.byName(json['status']! as String),
        requestedAt: DateTime.parse(json['requestedAt']! as String),
      );
}

/// The caregiver's earnings picture: available balance, history and payout
/// status. (FR-CM-21, FR-CM-22, FR-P-29)
class EarningsSummary {
  const EarningsSummary({
    this.earnings = const [],
    this.withdrawals = const [],
    this.pendingBalance = 0,
  });

  /// Finished-booking earnings, newest first.
  final List<EarningEntry> earnings;

  /// Withdrawal requests, newest first.
  final List<Withdrawal> withdrawals;

  /// Expected earnings from a session still running. It is not withdrawable
  /// until the session finishes and the platform releases it. (FR-P-21)
  final int pendingBalance;

  int get totalEarned =>
      earnings.fold(0, (sum, entry) => sum + entry.amount);

  int get totalWithdrawn =>
      withdrawals.fold(0, (sum, item) => sum + item.amount);

  int get totalPaidOut => withdrawals
      .where((item) => item.status == PayoutStatus.paid)
      .fold(0, (sum, item) => sum + item.amount);

  /// Balance the caregiver can still withdraw. Requests reserve their amount
  /// straight away, so this never goes negative.
  int get availableBalance {
    final balance = totalEarned - totalWithdrawn;
    return balance < 0 ? 0 : balance;
  }

  bool get isEmpty => earnings.isEmpty && withdrawals.isEmpty;

  Map<String, Object?> toJson() => {
        'earnings': earnings.map((entry) => entry.toJson()).toList(),
        'withdrawals': withdrawals.map((item) => item.toJson()).toList(),
        'pendingBalance': pendingBalance,
      };

  factory EarningsSummary.fromJson(Map<String, Object?> json) => EarningsSummary(
        earnings: (json['earnings'] as List<Object?>? ?? const [])
            .map((item) => EarningEntry.fromJson(item! as Map<String, Object?>))
            .toList(),
        withdrawals: (json['withdrawals'] as List<Object?>? ?? const [])
            .map((item) => Withdrawal.fromJson(item! as Map<String, Object?>))
            .toList(),
        pendingBalance: json['pendingBalance'] as int? ?? 0,
      );
}

/// Result of a withdrawal request. (FR-CM-22)
class WithdrawalResult {
  const WithdrawalResult.succeeded(this.amount)
      : success = true,
        message = null;

  const WithdrawalResult.failed(this.message)
      : success = false,
        amount = 0;

  final bool success;
  final int amount;
  final String? message;
}

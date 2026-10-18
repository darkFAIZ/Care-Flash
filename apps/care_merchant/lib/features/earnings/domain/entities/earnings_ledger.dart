import 'package:equatable/equatable.dart';

class TransactionRecord extends Equatable {
  final String id;
  final String bookingReference;
  final DateTime timestamp;
  final int amountIdr;
  final String description;
  final String status; // "settled", "pending", "withdrawn"

  const TransactionRecord({
    required this.id,
    required this.bookingReference,
    required this.timestamp,
    required this.amountIdr,
    required this.description,
    required this.status,
  });

  @override
  List<Object?> get props => [
        id,
        bookingReference,
        timestamp,
        amountIdr,
        description,
        status,
      ];
}

class EarningsLedger extends Equatable {
  final int availableBalanceIdr;
  final int pendingBalanceIdr;
  final int lifetimeEarningsIdr;
  final List<TransactionRecord> transactions;

  const EarningsLedger({
    required this.availableBalanceIdr,
    required this.pendingBalanceIdr,
    required this.lifetimeEarningsIdr,
    required this.transactions,
  });

  EarningsLedger copyWith({
    int? availableBalanceIdr,
    int? pendingBalanceIdr,
    int? lifetimeEarningsIdr,
    List<TransactionRecord>? transactions,
  }) {
    return EarningsLedger(
      availableBalanceIdr: availableBalanceIdr ?? this.availableBalanceIdr,
      pendingBalanceIdr: pendingBalanceIdr ?? this.pendingBalanceIdr,
      lifetimeEarningsIdr: lifetimeEarningsIdr ?? this.lifetimeEarningsIdr,
      transactions: transactions ?? this.transactions,
    );
  }

  @override
  List<Object?> get props => [
        availableBalanceIdr,
        pendingBalanceIdr,
        lifetimeEarningsIdr,
        transactions,
      ];
}

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/network/platform_api_client.dart';
import '../../domain/entities/earnings_ledger.dart';

// Events
abstract class EarningsEvent extends Equatable {
  const EarningsEvent();
  @override
  List<Object?> get props => [];
}

class FetchEarningsRequested extends EarningsEvent {
  const FetchEarningsRequested();
}

class WithdrawalRequested extends EarningsEvent {
  final int amountIdr;
  final String bankName;
  final String accountNumber;

  const WithdrawalRequested({
    required this.amountIdr,
    required this.bankName,
    required this.accountNumber,
  });

  @override
  List<Object?> get props => [amountIdr, bankName, accountNumber];
}

// States
abstract class EarningsState extends Equatable {
  const EarningsState();
  @override
  List<Object?> get props => [];
}

class EarningsInitial extends EarningsState {
  const EarningsInitial();
}

class EarningsLoading extends EarningsState {
  const EarningsLoading();
}

class EarningsLoaded extends EarningsState {
  final EarningsLedger ledger;
  final String? successMessage;
  final String? errorMessage;

  const EarningsLoaded({
    required this.ledger,
    this.successMessage,
    this.errorMessage,
  });

  EarningsLoaded copyWith({
    EarningsLedger? ledger,
    String? successMessage,
    String? errorMessage,
  }) {
    return EarningsLoaded(
      ledger: ledger ?? this.ledger,
      successMessage: successMessage,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [ledger, successMessage, errorMessage];
}

class EarningsError extends EarningsState {
  final String message;

  const EarningsError(this.message);

  @override
  List<Object?> get props => [message];
}

// BLoC
class EarningsBloc extends Bloc<EarningsEvent, EarningsState> {
  final PlatformApiClient apiClient;

  EarningsBloc({required this.apiClient}) : super(const EarningsInitial()) {
    on<FetchEarningsRequested>(_onFetchEarningsRequested);
    on<WithdrawalRequested>(_onWithdrawalRequested);
  }

  Future<void> _onFetchEarningsRequested(
    FetchEarningsRequested event,
    Emitter<EarningsState> emit,
  ) async {
    emit(const EarningsLoading());
    try {
      final ledger = await apiClient.getEarningsLedger();
      emit(EarningsLoaded(ledger: ledger));
    } catch (e) {
      emit(EarningsError(e.toString()));
    }
  }

  Future<void> _onWithdrawalRequested(
    WithdrawalRequested event,
    Emitter<EarningsState> emit,
  ) async {
    final currentState = state;
    if (currentState is! EarningsLoaded) return;

    if (event.amountIdr > currentState.ledger.availableBalanceIdr) {
      emit(currentState.copyWith(
        errorMessage: 'Insufficient available balance for withdrawal.',
        successMessage: null,
      ));
      return;
    }

    try {
      final success = await apiClient.requestPayout(
        event.amountIdr,
        event.bankName,
        event.accountNumber,
      );

      if (success) {
        final updatedLedger = await apiClient.getEarningsLedger();
        emit(EarningsLoaded(
          ledger: updatedLedger,
          successMessage: 'Withdrawal of ${event.amountIdr} IDR processed successfully!',
          errorMessage: null,
        ));
      } else {
        emit(currentState.copyWith(
          errorMessage: 'Failed to process withdrawal request.',
          successMessage: null,
        ));
      }
    } catch (e) {
      emit(currentState.copyWith(
        errorMessage: 'Withdrawal failed: ${e.toString()}',
        successMessage: null,
      ));
    }
  }
}

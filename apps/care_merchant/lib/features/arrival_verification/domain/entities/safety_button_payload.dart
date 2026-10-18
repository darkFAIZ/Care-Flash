import 'package:equatable/equatable.dart';

enum HandoverStage {
  awaitingClientCodeInput,
  clientCodeVerified,
  generatingSafetyButtonPayload,
  awaitingSeekerButtonScan,
  handoverCompleted,
}

class SafetyButtonPayload extends Equatable {
  final String bookingId;
  final String buttonToken;
  final String qrDataUri;
  final String nfcPayloadString;
  final DateTime issuedAt;

  const SafetyButtonPayload({
    required this.bookingId,
    required this.buttonToken,
    required this.qrDataUri,
    required this.nfcPayloadString,
    required this.issuedAt,
  });

  @override
  List<Object?> get props => [
        bookingId,
        buttonToken,
        qrDataUri,
        nfcPayloadString,
        issuedAt,
      ];
}

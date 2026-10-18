import 'package:equatable/equatable.dart';

class RequestOffer extends Equatable {
  final String requestReference;
  final String helpType;
  final String? description;
  final List<String> boundaryChecklist;
  final int durationMinutes;
  final int expectedEarningsIdr;
  final DateTime expiresAt;

  const RequestOffer({
    required this.requestReference,
    required this.helpType,
    this.description,
    required this.boundaryChecklist,
    required this.durationMinutes,
    required this.expectedEarningsIdr,
    required this.expiresAt,
  });

  factory RequestOffer.fromJson(Map<String, dynamic> json) {
    if (json.containsKey('address') ||
        json.containsKey('destinationAddress') ||
        json.containsKey('code') ||
        json.containsKey('clientCode') ||
        json.containsKey('latitude') ||
        json.containsKey('longitude')) {
      throw const FormatException(
        'Privacy violation: address, coordinates, and verification code must not be exposed in RequestOffer',
      );
    }

    return RequestOffer(
      requestReference: json['requestReference'] as String,
      helpType: json['helpType'] as String,
      description: json['description'] as String?,
      boundaryChecklist: List<String>.from(json['boundaryChecklist'] as List),
      durationMinutes: json['durationMinutes'] as int,
      expectedEarningsIdr: json['expectedEarningsIdr'] as int,
      expiresAt: DateTime.parse(json['expiresAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'requestReference': requestReference,
      'helpType': helpType,
      'description': description,
      'boundaryChecklist': boundaryChecklist,
      'durationMinutes': durationMinutes,
      'expectedEarningsIdr': expectedEarningsIdr,
      'expiresAt': expiresAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        requestReference,
        helpType,
        description,
        boundaryChecklist,
        durationMinutes,
        expectedEarningsIdr,
        expiresAt,
      ];
}

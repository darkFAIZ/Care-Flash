import 'package:flutter_test/flutter_test.dart';
import 'package:care_merchant/features/matching/domain/entities/request_offer.dart';

void main() {
  group('RequestOffer Privacy Protection', () {
    test('successfully parses valid JSON without private fields', () {
      final validJson = {
        'requestReference': 'CR-2026-9812',
        'helpType': 'Elderly Mobility Support',
        'description': 'Walking companionship',
        'boundaryChecklist': ['Walking only'],
        'durationMinutes': 60,
        'expectedEarningsIdr': 50000,
        'expiresAt': DateTime.now().toIso8601String(),
      };

      final offer = RequestOffer.fromJson(validJson);
      expect(offer.requestReference, 'CR-2026-9812');
      expect(offer.expectedEarningsIdr, 50000);
    });

    test('throws FormatException if address is present in offer JSON', () {
      final leakedJson = {
        'requestReference': 'CR-2026-9812',
        'helpType': 'Elderly Mobility Support',
        'address': 'Jl. Menteng No. 10',
        'boundaryChecklist': ['Walking only'],
        'durationMinutes': 60,
        'expectedEarningsIdr': 50000,
        'expiresAt': DateTime.now().toIso8601String(),
      };

      expect(() => RequestOffer.fromJson(leakedJson), throwsFormatException);
    });

    test('throws FormatException if clientCode is present in offer JSON', () {
      final leakedJson = {
        'requestReference': 'CR-2026-9812',
        'helpType': 'Elderly Mobility Support',
        'clientCode': '123456',
        'boundaryChecklist': ['Walking only'],
        'durationMinutes': 60,
        'expectedEarningsIdr': 50000,
        'expiresAt': DateTime.now().toIso8601String(),
      };

      expect(() => RequestOffer.fromJson(leakedJson), throwsFormatException);
    });

    test('throws FormatException if coordinates are present in offer JSON', () {
      final leakedJson = {
        'requestReference': 'CR-2026-9812',
        'helpType': 'Elderly Mobility Support',
        'latitude': -6.1950,
        'longitude': 106.8320,
        'boundaryChecklist': ['Walking only'],
        'durationMinutes': 60,
        'expectedEarningsIdr': 50000,
        'expiresAt': DateTime.now().toIso8601String(),
      };

      expect(() => RequestOffer.fromJson(leakedJson), throwsFormatException);
    });
  });
}

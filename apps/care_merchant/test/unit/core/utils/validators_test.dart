import 'package:flutter_test/flutter_test.dart';
import 'package:care_merchant/core/utils/validators.dart';

void main() {
  group('Validators', () {
    test('validatePin returns true for 6-digit PIN', () {
      expect(Validators.validatePin('123456'), isTrue);
    });

    test('validatePin returns false for non-6-digit PIN', () {
      expect(Validators.validatePin('12345'), isFalse);
      expect(Validators.validatePin('1234567'), isFalse);
      expect(Validators.validatePin('abc123'), isFalse);
    });
  });
}

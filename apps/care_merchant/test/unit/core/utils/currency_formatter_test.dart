import 'package:flutter_test/flutter_test.dart';
import 'package:care_merchant/core/utils/currency_formatter.dart';

void main() {
  group('CurrencyFormatter', () {
    test('formats amount to IDR currency string', () {
      final result = CurrencyFormatter.toIdr(25000);
      expect(result, 'Rp 25.000');
    });
  });
}

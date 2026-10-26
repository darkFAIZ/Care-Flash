/// Small formatting helpers shared by both apps.
library;

/// Formats [amount] as Indonesian rupiah, for example `IDR 61,500`.
String formatIdr(int amount) {
  final digits = amount.abs().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) {
      buffer.write(',');
    }
    buffer.write(digits[i]);
  }
  return 'IDR ${amount < 0 ? '-' : ''}$buffer';
}

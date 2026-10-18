import 'package:intl/intl.dart';

class CurrencyFormatter {
  static String toIdr(int amount) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return formatter.format(amount).replaceAll('\u00a0', ' ').trim();
  }
}

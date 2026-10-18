class Validators {
  static bool validatePin(String? value) {
    if (value == null) return false;
    final pinRegex = RegExp(r'^\d{6}$');
    return pinRegex.hasMatch(value);
  }
}

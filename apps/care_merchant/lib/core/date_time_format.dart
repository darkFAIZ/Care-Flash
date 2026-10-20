/// Date and time formatting helpers for Care-Merchant.
///
/// Kept local and dependency-free (no intl) because the prototype only needs
/// English short dates. Replace with intl when localisation is added. (FR-CM-3)
library;

const List<String> _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

String _two(int value) => value.toString().padLeft(2, '0');

/// Formats just the clock time, for example `15:00`.
String formatClock(DateTime value) =>
    '${_two(value.hour)}:${_two(value.minute)}';

/// Formats a visit time, for example `20 Oct 2026, 15:00`.
String formatVisitTime(DateTime value) =>
    '${value.day} ${_months[value.month - 1]} ${value.year}, '
    '${formatClock(value)}';

/// Formats an elapsed or remaining duration for the session timer, for example
/// `01:23:45`. (FR-CM-17)
String formatTimer(Duration value) {
  final total = value.isNegative ? Duration.zero : value;
  final hours = total.inHours;
  final minutes = total.inMinutes % 60;
  final seconds = total.inSeconds % 60;
  return '${_two(hours)}:${_two(minutes)}:${_two(seconds)}';
}

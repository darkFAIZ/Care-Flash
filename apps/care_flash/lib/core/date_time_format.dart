/// Date and time formatting helpers for Care-Flash.
///
/// Kept local and dependency-free (no intl) because the prototype only needs
/// English short dates. Replace with intl when localisation is added. (FR-CS-3)
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

/// Pure-Dart demo backend for the Care-Flash platform.
///
/// Holds the single source of truth for bookings, accounts, earnings and
/// feedback, and exposes it over WebSocket so the two Flutter apps (running as
/// separate processes) genuinely talk to each other. (AGENTS.md §5)
library;

export 'src/server.dart';
export 'src/state.dart';

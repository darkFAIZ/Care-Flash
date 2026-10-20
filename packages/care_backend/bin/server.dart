import 'dart:async';

import 'package:care_backend/care_backend.dart';

/// Entry point for the Care-Flash demo backend.
///
/// Run with: `dart run packages/care_backend/bin/server.dart [port]` (defaults
/// to 8080). Both Flutter apps connect to it over WebSocket so they share one
/// booking state and genuinely talk to each other. (AGENTS.md §5)
Future<void> main(List<String> args) async {
  final port = args.isNotEmpty ? int.tryParse(args.first) ?? 8080 : 8080;
  final server = CareBackendServer(port: port);
  await server.start();
  // Keep the process alive until interrupted; the listening socket is the
  // actual event source.
  await Completer<void>().future;
}

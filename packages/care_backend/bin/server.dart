import 'dart:async';
import 'dart:io';

import 'package:care_backend/care_backend.dart';

/// Entry point for the Care-Flash demo backend.
///
/// Run with: `dart run packages/care_backend/bin/server.dart [port]` (defaults
/// to 8080). Both Flutter apps connect to it over WebSocket so they share one
/// booking state and genuinely talk to each other. (AGENTS.md §5)
Future<void> main(List<String> args) async {
  final environment = Platform.environment;
  final port = args.isNotEmpty
      ? int.tryParse(args.first) ?? 8080
      : int.tryParse(environment['PORT'] ?? '') ?? 8080;
  final host = args.length > 1 ? args[1] : environment['HOST'] ?? '0.0.0.0';
  final dataFilePath =
      environment['CARE_DATA_FILE'] ??
      'packages/care_backend/data/care_backend.json';
  final server = CareBackendServer(
    port: port,
    host: host,
    dataFilePath: dataFilePath,
  );
  await server.start();
  // Keep the process alive until interrupted; the listening socket is the
  // actual event source.
  await Completer<void>().future;
}

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:care_backend/care_backend.dart';

/// Entry point for the Care-Flash demo backend.
///
/// Run with:
/// `dart run packages/care_backend/bin/server.dart [--host 127.0.0.1] [--port 8080] [--data data/backend.json]`
///
/// Both Flutter apps connect over WebSocket so they share one booking state.
/// With `--data`, accounts and sign-in tokens survive a restart; bookings do
/// not (they are still in memory only). Use `--host 0.0.0.0` to reach the
/// backend from a phone on the same Wi-Fi. (AGENTS.md §5)
Future<void> main(List<String> args) async {
  var port = 8080;
  var host = '127.0.0.1';
  String? dataPath;
  for (var i = 0; i < args.length; i++) {
    final arg = args[i];
    if (arg == '--port' && i + 1 < args.length) {
      port = int.tryParse(args[++i]) ?? port;
    } else if (arg.startsWith('--port=')) {
      port = int.tryParse(arg.substring('--port='.length)) ?? port;
    } else if (arg == '--host' && i + 1 < args.length) {
      host = args[++i];
    } else if (arg.startsWith('--host=')) {
      host = arg.substring('--host='.length);
    } else if (arg == '--data' && i + 1 < args.length) {
      dataPath = args[++i];
    } else if (arg.startsWith('--data=')) {
      dataPath = arg.substring('--data='.length);
    } else {
      // Backwards compatible: the first bare argument is the port.
      port = int.tryParse(arg) ?? port;
    }
  }

  var state = CareBackendState();
  if (dataPath != null) {
    final file = File(dataPath);
    if (await file.exists()) {
      try {
        state = CareBackendState.fromJson(
          jsonDecode(await file.readAsString()) as Map<String, Object?>,
        );
        // ignore: avoid_print
        print('Loaded accounts and sessions from $dataPath');
      } catch (error) {
        // ignore: avoid_print
        print('Could not read $dataPath ($error); starting with a clean state.');
        state = CareBackendState();
      }
    }
  }

  var saving = Future<void>.value();
  void save(CareBackendState next) {
    if (dataPath == null) return;
    final encoded = jsonEncode(next.toJson());
    saving = saving.then((_) async {
      final file = File(dataPath!);
      await file.parent.create(recursive: true);
      await file.writeAsString(encoded);
    }).catchError((Object error) {
      // ignore: avoid_print
      print('Could not save $dataPath: $error');
    });
  }

  final server =
      CareBackendServer(port: port, host: host, state: state, onStateChanged: save);
  await server.start();
  // Keep the process alive until interrupted; the listening socket is the
  // actual event source.
  await Completer<void>().future;
}

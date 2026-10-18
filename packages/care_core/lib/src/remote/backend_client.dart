import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

/// Raised when the backend rejects an operation or the connection drops.
class BackendException implements Exception {
  const BackendException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// A tiny JSON-RPC client over one WebSocket connection to the demo backend.
///
/// Request/response messages are matched by an incrementing id; the backend
/// additionally pushes full role snapshots on the `snapshot` stream after every
/// operation. This is the transport used by [RemoteCarePlatform] and
/// [RemoteCaregiverPlatform] so the two apps share one booking state.
class CareBackendClient {
  CareBackendClient(this.url);

  /// WebSocket URL, for example `ws://localhost:8080`.
  final String url;

  final StreamController<Map<String, Object?>> _snapshots =
      StreamController<Map<String, Object?>>.broadcast();
  final Map<int, Completer<Object?>> _pending = {};

  WebSocketChannel? _channel;
  int _nextRequest = 1;

  /// Snapshots pushed by the backend, one per operation after sign-in.
  Stream<Map<String, Object?>> get snapshots => _snapshots.stream;

  bool get isConnected => _channel != null;

  /// Opens the connection. Call once before using the platform.
  Future<void> connect() async {
    if (_channel != null) return;
    final channel = WebSocketChannel.connect(Uri.parse(url));
    await channel.ready;
    _channel = channel;
    channel.stream.listen(
      _onData,
      onDone: () => _failAll(const BackendException('The backend connection closed.')),
      onError: (Object error) => _failAll(BackendException('$error')),
      cancelOnError: true,
    );
  }

  /// Sends an operation and completes with its result value.
  Future<Object?> call(String op, [Map<String, Object?> args = const {}]) {
    final channel = _channel;
    if (channel == null) {
      return Future<Object?>.error(
        const BackendException('Not connected to the backend.'),
      );
    }
    final request = _nextRequest++;
    final completer = Completer<Object?>();
    _pending[request] = completer;
    channel.sink.add(jsonEncode({'req': request, 'op': op, 'args': args}));
    return completer.future;
  }

  Future<void> close() async {
    await _channel?.sink.close();
    _channel = null;
  }

  void _onData(Object? raw) {
    final Object? decoded = raw is String ? jsonDecode(raw) : jsonDecode(utf8.decode(raw! as List<int>));
    final message = decoded! as Map<String, Object?>;
    if (message['stream'] == 'snapshot') {
      _snapshots.add(message['data']! as Map<String, Object?>);
      return;
    }
    final request = message['res'] as int?;
    final completer = request == null ? null : _pending.remove(request);
    if (completer == null || completer.isCompleted) return;
    if (message['ok'] == true) {
      completer.complete(message['val']);
    } else {
      completer.completeError(
        BackendException(message['err'] as String? ?? 'Backend error'),
      );
    }
  }

  void _failAll(Object error) {
    _channel = null;
    for (final completer in _pending.values) {
      if (!completer.isCompleted) completer.completeError(error);
    }
    _pending.clear();
  }
}

/// Decodes a nullable model map, or null when [value] is null.
T? decodeOrNull<T>(Object? value, T Function(Map<String, Object?>) fromJson) =>
    value == null ? null : fromJson(value as Map<String, Object?>);

/// Decodes a list of model maps, defaulting to an empty list.
List<T> decodeList<T>(Object? value, T Function(Map<String, Object?>) fromJson) =>
    (value as List<Object?>? ?? const [])
        .map((item) => fromJson(item! as Map<String, Object?>))
        .toList();

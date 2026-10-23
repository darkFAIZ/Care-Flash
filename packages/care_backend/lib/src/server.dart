import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:care_domain/care_domain.dart';

import 'state.dart';

/// A connected app instance (one Care-Flash or Care-Merchant window).
class _Conn {
  _Conn(this.socket);

  final WebSocket socket;

  /// null until the app signs in, then `seeker` or `caregiver`.
  String? role;
  String? userId;

  bool get isAuthed => role != null && userId != null;

  void send(Map<String, Object?> message) {
    if (socket.closeCode == null) {
      socket.add(jsonEncode(message));
    }
  }
}

/// The demo backend: a small WebSocket server over [CareBackendState].
///
/// Each Flutter app connects as a care seeker or a caregiver. After every
/// operation the server pushes a role-appropriate snapshot to every connected
/// app, so a booking created in Care-Flash shows up live in Care-Merchant and
/// vice versa. (AGENTS.md §5)
class CareBackendServer {
  CareBackendServer({
    this.port = 8080,
    this.host = '127.0.0.1',
    this.dataFilePath,
    CareBackendState? state,
  }) : state = state ?? CareBackendState();

  final int port;

  /// Interface to listen on. Use `0.0.0.0` for emulator/phone access.
  final String host;

  /// Optional JSON state file. Leave null for isolated in-memory tests.
  final String? dataFilePath;
  final CareBackendState state;

  HttpServer? _server;
  final Map<WebSocket, _Conn> _conns = {};
  Future<void> _persistenceQueue = Future<void>.value();

  /// The port the server is actually listening on, or null before [start].
  /// Useful when constructed with port 0 to pick a free port (tests).
  int? get boundPort => _server?.port;

  Future<void> start() async {
    await _loadState();
    final address =
        InternetAddress.tryParse(host) ??
        (host == 'localhost'
            ? InternetAddress.loopbackIPv4
            : InternetAddress.anyIPv4);
    final server = await HttpServer.bind(address, port);
    _server = server;
    // ignore: avoid_print
    print(
      'Care-Flash shared backend listening on ${address.address}:${server.port}',
    );
    server.listen(_onRequest, onError: (_) {});
  }

  Future<void> _onRequest(HttpRequest request) async {
    if (WebSocketTransformer.isUpgradeRequest(request)) {
      final socket = await WebSocketTransformer.upgrade(request);
      _onConnection(socket);
    } else if (request.uri.path == '/health') {
      request.response
        ..statusCode = HttpStatus.ok
        ..headers.contentType = ContentType.json
        ..write('{"status":"ok"}');
      await request.response.close();
    } else {
      request.response
        ..statusCode = HttpStatus.ok
        ..headers.contentType = ContentType.text
        ..write('Care-Flash demo backend. Connect over WebSocket.');
      await request.response.close();
    }
  }

  Future<void> stop() async {
    for (final socket in _conns.keys.toList()) {
      await socket.close();
    }
    _conns.clear();
    await _server?.close(force: true);
    _server = null;
  }

  void _onConnection(WebSocket socket) {
    final conn = _Conn(socket);
    _conns[socket] = conn;
    socket.listen(
      (data) => _onMessage(conn, data),
      onDone: () => _conns.remove(socket),
      onError: (_) => _conns.remove(socket),
      cancelOnError: true,
    );
  }

  Future<void> _onMessage(_Conn conn, Object? data) async {
    Map<String, Object?> msg;
    try {
      msg = jsonDecode(data! as String) as Map<String, Object?>;
    } catch (_) {
      return;
    }
    final req = msg['req'];
    final op = msg['op'];
    if (req is! int || op is! String) return;
    final args =
        (msg['args'] as Map<String, Object?>?) ?? const <String, Object?>{};

    try {
      final val = _dispatch(conn, op, args);
      await _persistState();
      conn.send({'res': req, 'ok': true, 'val': val});
    } catch (e) {
      conn.send({'res': req, 'ok': false, 'err': _cleanError(e)});
    }
    _broadcast();
  }

  Future<void> _loadState() async {
    final path = dataFilePath;
    if (path == null) return;
    final file = File(path);
    if (!await file.exists()) return;
    final decoded = jsonDecode(await file.readAsString());
    state.restoreFromJson(Map<String, Object?>.from(decoded as Map));
  }

  Future<void> _persistState() async {
    final path = dataFilePath;
    if (path == null) return;
    final write = _persistenceQueue.then((_) async {
      final file = File(path);
      await file.parent.create(recursive: true);
      final temporary = File('$path.tmp');
      await temporary.writeAsString(jsonEncode(state.toJson()), flush: true);
      if (await file.exists()) await file.delete();
      await temporary.rename(path);
    });
    _persistenceQueue = write.catchError((Object _) {});
    await write;
  }

  String _cleanError(Object e) {
    final s = e.toString();
    final prefix = 'Bad state: ';
    return s.startsWith(prefix) ? s.substring(prefix.length) : s;
  }

  Object? _dispatch(_Conn conn, String op, Map<String, Object?> args) {
    switch (op) {
      // ----- auth (sets the connection identity) -----
      case 'seekerSignUp':
        final r = state.seekerSignUp(
          name: args['name']! as String,
          email: args['email']! as String,
          password: args['password']! as String,
        );
        _bind(conn, r);
        return r;
      case 'seekerSignIn':
        final r = state.seekerSignIn(
          email: args['email']! as String,
          password: args['password']! as String,
        );
        _bind(conn, r);
        return r;
      case 'caregiverSignUp':
        final r = state.caregiverSignUp(
          name: args['name']! as String,
          email: args['email']! as String,
          password: args['password']! as String,
          gender: Gender.values.byName(args['gender']! as String),
        );
        _bind(conn, r);
        return r;
      case 'caregiverSignIn':
        final r = state.caregiverSignIn(
          email: args['email']! as String,
          password: args['password']! as String,
        );
        _bind(conn, r);
        return r;

      // ----- care seeker lifecycle -----
      case 'submitRequest':
        return state.submitRequest(_seeker(conn), args);
      case 'retryWithGenderFilter':
        return state.retryWithGenderFilter(
          _seeker(conn),
          GenderFilter.values.byName(args['filter']! as String),
        );
      case 'pay':
        return state.pay(
          _seeker(conn),
          args['bookingId']! as String,
          PaymentMethodType.values.byName(args['method']! as String),
        );
      case 'cancelBooking':
        state.cancelBooking(
          _seeker(conn),
          CancellationReason.values.byName(args['reason']! as String),
        );
        return null;
      case 'verifyCaregiverCode':
        return state.verifyCaregiverCode(
          _seeker(conn),
          args['code']! as String,
        );
      case 'verifySafetyButton':
        return state.verifySafetyButton(
          _seeker(conn),
          ButtonVerification(
            method: ButtonVerificationMethod.values.byName(
              args['method']! as String,
            ),
            payload: args['payload']! as String,
          ),
        );
      case 'endEarly':
        state.endEarly(_seeker(conn));
        return null;
      case 'reportIncident':
        state.reportIncident(
          _seeker(conn),
          IncidentReport.fromJson(args['report']! as Map<String, Object?>),
        );
        return null;
      case 'rateCaregiver':
        state.rateCaregiver(_seeker(conn), args);
        return null;
      case 'submitAppFeedback':
        state.submitAppFeedback(args);
        return null;

      // ----- caregiver onboarding -----
      case 'submitVerification':
        state.submitVerification(
          _caregiver(conn),
          residentialIdNumber: args['residentialIdNumber']! as String,
          documentLabel: args['documentLabel']! as String,
        );
        return null;
      case 'completeSafetyModule':
        state.completeSafetyModule(_caregiver(conn));
        return null;
      case 'updateGender':
        state.updateGender(
          _caregiver(conn),
          Gender.values.byName(args['gender']! as String),
        );
        return null;
      case 'updateAvailability':
        state.updateAvailability(
          _caregiver(conn),
          CaregiverAvailability.values.byName(args['availability']! as String),
        );
        return null;

      // ----- caregiver request + session lifecycle -----
      case 'acceptRequest':
        state.acceptRequest(_caregiver(conn));
        return null;
      case 'declineRequest':
        state.declineRequest(_caregiver(conn));
        return null;
      case 'reportDanger':
        state.reportDanger(_caregiver(conn), args['description']! as String);
        return null;
      case 'startTrip':
        state.startTrip(_caregiver(conn));
        return null;
      case 'markArrived':
        state.markArrived(_caregiver(conn));
        return null;
      case 'completeSession':
        state.completeSession(_caregiver(conn));
        return null;
      case 'sos':
        state.sos(_caregiver(conn), args['description']! as String);
        return null;
      case 'reportCareSeeker':
        state.reportCareSeeker(
          _caregiver(conn),
          IncidentReport.fromJson(args['report']! as Map<String, Object?>),
        );
        return null;
      case 'rateCareSeeker':
        state.rateCareSeeker(_caregiver(conn), args);
        return null;
      case 'requestWithdrawal':
        return state.requestWithdrawal(
          _caregiver(conn),
          args['amount']! as int,
        );

      default:
        throw StateError('Unknown operation: $op');
    }
  }

  void _bind(_Conn conn, Map<String, Object?> authResult) {
    if (authResult['success'] != true) return;
    final user = authResult['user'] as Map<String, Object?>?;
    if (user == null) return;
    final isCaregiver = user.containsKey('verificationStatus');
    conn.role = isCaregiver ? 'caregiver' : 'seeker';
    conn.userId = user['id']! as String;
  }

  String _seeker(_Conn conn) => _actor(conn, 'seeker');
  String _caregiver(_Conn conn) => _actor(conn, 'caregiver');

  String _actor(_Conn conn, String role) {
    if (conn.role != role || conn.userId == null) {
      throw StateError('Sign in as a $role first.');
    }
    return conn.userId!;
  }

  void _broadcast() {
    for (final conn in _conns.values) {
      if (!conn.isAuthed) continue;
      final snapshot = conn.role == 'seeker'
          ? state.seekerSnapshot(conn.userId!)
          : state.caregiverSnapshot(conn.userId!);
      conn.send({'stream': 'snapshot', 'data': snapshot});
    }
  }
}

import 'dart:async';

import 'package:care_domain/care_domain.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../mock/mock_data.dart';

/// Supabase-backed implementations shared by the two Flutter frontends.
/// Both clients use Supabase Auth, Postgres, RLS, RPCs, and Realtime.
class SupabaseCareSeekerPlatform implements CareSeekerPlatform {
  SupabaseCareSeekerPlatform(SupabaseClient client) : _store = _CareStore(client);
  final _CareStore _store;
  Future<void> initialize() => _store.ready;

  @override
  CareSeeker? get currentUser => _store.seeker;
  @override
  Stream<CareSeeker?> watchCurrentUser() async* { yield _store.seeker; yield* _store.seekerChanges.stream; }
  @override
  Future<AuthResult> signUp({required String name, required String email, required String password}) =>
      _store.signUpSeeker(name: name, email: email, password: password);
  @override
  Future<AuthResult> signIn({required String email, required String password}) =>
      _store.signInSeeker(email: email, password: password);
  @override
  Future<void> signOut() => _store.signOut();
  @override
  Booking? get activeBooking => _store.activeSeekerBooking;
  @override
  Stream<Booking?> watchActiveBooking() async* { yield _store.activeSeekerBooking; yield* _store.seekerBookingChanges.stream; }
  @override
  Stream<List<Booking>> watchBookingHistory() async* { yield _store.seekerHistory; yield* _store.seekerHistoryChanges.stream; }
  @override
  Future<Booking> submitRequest(HelpRequest request) => _store.submitRequest(request);
  @override
  Future<Booking> retryWithGenderFilter(GenderFilter filter) =>
      _store.retryWithGenderFilter(filter);
  @override
  Future<void> cancelBooking(CancellationReason reason) =>
      _store.action('cancel', {'reason': reason.name});
  @override
  Future<ButtonVerificationResult> verifyCaregiverCode(String code) async {
    final result = await _store.actionResult('verifyCode', {'code': code});
    return result['success'] == true
        ? const ButtonVerificationResult.success()
        : ButtonVerificationResult.failed(result['message'] as String? ?? 'That code is incorrect.');
  }
  @override
  Future<ButtonVerificationResult> verifySafetyButton(ButtonVerification verification) async {
    final result = await _store.actionResult('verifyButton', {
      'method': verification.method.name,
      'payload': verification.payload,
    });
    return result['success'] == true
        ? const ButtonVerificationResult.success()
        : ButtonVerificationResult.failed(result['message'] as String? ?? 'Button verification failed.');
  }
  @override
  Future<void> endEarly() => _store.action('endEarly');
  @override
  Future<void> reportIncident(IncidentReport report) =>
      _store.action('report', report.toJson());
  @override
  Future<void> rateCaregiver(CaregiverRating rating) =>
      _store.saveRating('caregiver_ratings', rating.toJson());
  @override
  Future<void> submitAppFeedback(AppFeedback feedback) =>
      _store.saveFeedback(feedback.toJson());
  @override
  List<PaymentMethod> availableMethods() => MockData.paymentMethods;
  @override
  Future<PaymentResult> pay({required String bookingId, required PaymentMethod method}) async {
    final result = await _store.actionResult('pay', {'paymentMethod': method.toJson()}, bookingId);
    return result['success'] == true
        ? const PaymentResult.succeeded()
        : PaymentResult.failed(result['message'] as String? ?? 'Payment could not be completed.');
  }
  @override
  void setAutoAdvance(bool enabled) {}
  @override
  void setNextRequestMatches(bool matches) {}
  @override
  void setNextPaymentFails(bool fails) {}
  @override
  void simulateCaregiverAccept() {}
  @override
  void simulateCaregiverDecline() {}
  @override
  void simulateCaregiverTravelling() {}
  @override
  void simulateCaregiverArrival() {}
  @override
  void simulateCaregiverCodeVerification({bool valid = true}) {}
  @override
  void simulateButtonScan({ButtonVerificationMethod method = ButtonVerificationMethod.qr, bool valid = true}) {}
  @override
  void simulateButtonPress() {}
  @override
  void simulateSessionComplete() {}
}

class SupabaseCaregiverPlatform implements CaregiverPlatform {
  SupabaseCaregiverPlatform(SupabaseClient client) : _store = _CareStore(client);
  final _CareStore _store;
  Future<void> initialize() => _store.ready;

  @override
  String? get debugClientCode => _store.activeCaregiverBooking?.clientCode;
  @override
  CaregiverAccount? get currentCaregiver => _store.caregiver;
  @override
  Stream<CaregiverAccount?> watchCurrentCaregiver() async* { yield _store.caregiver; yield* _store.caregiverChanges.stream; }
  @override
  Future<CaregiverAuthResult> signUp({required String name, required String email, required String password, required Gender gender}) =>
      _store.signUpCaregiver(name: name, email: email, password: password, gender: gender);
  @override
  Future<CaregiverAuthResult> signIn({required String email, required String password}) =>
      _store.signInCaregiver(email: email, password: password);
  @override
  Future<void> signOut() => _store.signOut();
  @override
  Future<void> submitVerification({required String residentialIdNumber, required String documentLabel}) =>
      _store.submitCaregiverVerification();
  @override
  Future<void> completeSafetyModule() => _store.completeSafetyModule();
  @override
  Future<void> updateGender(Gender gender) => _store.updateGender(gender);
  @override
  Future<void> updateAvailability(CaregiverAvailability availability) => _store.updateAvailability(availability);
  @override
  Stream<Booking?> watchIncomingRequest() async* { yield _store.incoming; yield* _store.incomingChanges.stream; }
  @override
  Stream<Booking?> watchActiveBooking() async* { yield _store.activeCaregiverBooking; yield* _store.caregiverBookingChanges.stream; }
  @override
  Stream<List<Booking>> watchBookingHistory() async* { yield _store.caregiverHistory; yield* _store.caregiverHistoryChanges.stream; }
  @override
  Future<void> acceptRequest() => _store.action('accept');
  @override
  Future<void> declineRequest() => _store.action('decline');
  @override
  Future<void> reportDanger(String description) => _store.action('report', {'description': description});
  @override
  Future<void> startTrip() => _store.action('startTrip');
  @override
  Future<void> markArrived() => _store.action('arrive');
  @override
  Future<void> completeSession() => _store.action('complete');
  @override
  Future<void> sos(String description) => _store.action('sos', {'description': description});
  @override
  Future<void> reportCareSeeker(IncidentReport report) => _store.action('report', report.toJson());
  @override
  Stream<EarningsSummary> watchEarnings() => Stream.value(const EarningsSummary());
  @override
  Future<WithdrawalResult> requestWithdrawal(int amount) => Future.value(const WithdrawalResult.failed('Payouts are not configured yet.'));
  @override
  Stream<List<FeedbackReceived>> watchFeedbackReceived() => Stream.value(const []);
  @override
  Stream<List<CareSeekerRating>> watchCareSeekerRatings() => Stream.value(const []);
  @override
  Future<void> rateCareSeeker(CareSeekerRating rating) =>
      _store.saveRating('care_seeker_ratings', rating.toJson());
  @override
  void setAutoAdvance(bool enabled) {}
  @override
  void setNextVerificationFails(bool fails) {}
  @override
  void simulateIncomingRequest() {}
  @override
  void simulateCareSeekerCancel() {}
  @override
  void simulateCareSeekerCodeConfirmation({bool valid = true}) {}
  @override
  void simulateCareSeekerButtonScan({ButtonVerificationMethod method = ButtonVerificationMethod.qr, bool valid = true}) {}
  @override
  void simulateCareSeekerEndEarly() {}
}

class _CareStore {
  _CareStore(this.client) {
    client.channel('care-bookings-${client.auth.currentUser?.id ?? 'signed-out'}')
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'bookings',
        callback: (_) => refresh(),
      )
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'caregiver_profiles',
        callback: (_) => refresh(),
      )
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'profiles',
        callback: (_) => refresh(),
      )
      ..subscribe();
    client.auth.onAuthStateChange.listen((_) => refresh());
    ready = refresh();
  }
  final SupabaseClient client;
  late final Future<void> ready;
  CareSeeker? seeker;
  CaregiverAccount? caregiver;
  Booking? activeSeekerBooking;
  Booking? activeCaregiverBooking;
  Booking? incoming;
  List<Booking> seekerHistory = const [];
  List<Booking> caregiverHistory = const [];
  final seekerChanges = StreamController<CareSeeker?>.broadcast();
  final caregiverChanges = StreamController<CaregiverAccount?>.broadcast();
  final seekerBookingChanges = StreamController<Booking?>.broadcast();
  final caregiverBookingChanges = StreamController<Booking?>.broadcast();
  final incomingChanges = StreamController<Booking?>.broadcast();
  final seekerHistoryChanges = StreamController<List<Booking>>.broadcast();
  final caregiverHistoryChanges = StreamController<List<Booking>>.broadcast();
  bool _refreshing = false;

  Future<void> refresh() async {
    if (_refreshing || client.auth.currentUser == null) return;
    _refreshing = true;
    try {
      final profile = await client.from('profiles').select().eq('id', client.auth.currentUser!.id).maybeSingle();
      if (profile == null) return;
      final role = profile['role'] as String;
      final name = profile['full_name'] as String? ?? '';
      final email = client.auth.currentUser?.email ?? '';
      if (role == 'seeker') {
        seeker = CareSeeker(id: profile['id'] as String, name: name, email: email, phone: profile['phone'] as String?);
        seekerChanges.add(seeker);
      } else {
        final cp = await client.from('caregiver_profiles').select().eq('user_id', profile['id'] as String).maybeSingle();
        if (cp != null) {
          caregiver = CaregiverAccount(
            id: profile['id'] as String, name: name, email: email,
            gender: Gender.values.byName(cp['gender'] as String),
            rating: (cp['rating'] as num).toDouble(), reviewCount: cp['review_count'] as int,
            verificationStatus: _verification(cp['verification_status'] as String),
            safetyModuleCompleted: cp['safety_module_completed'] as bool,
            availability: (cp['availability'] as String) == 'available' ? CaregiverAvailability.available : CaregiverAvailability.unavailable,
          );
          caregiverChanges.add(caregiver);
        }
      }
      final rows = await client.from('bookings').select().order('created_at', ascending: false);
      final bookings = await Future.wait((rows as List).map((row) => _booking(Map<String, Object?>.from(row as Map))));
      final open = bookings.where((b) => b.status.isOpen).toList();
      if (role == 'seeker') {
        activeSeekerBooking = open.firstOrNull;
        seekerHistory = bookings.where((b) => b.status.isFinished).toList();
        seekerBookingChanges.add(activeSeekerBooking);
        seekerHistoryChanges.add(seekerHistory);
      } else {
        incoming = bookings.where((b) => b.status == BookingStatus.paidPending).firstOrNull;
        activeCaregiverBooking = open.where((b) => b.status != BookingStatus.paidPending).firstOrNull;
        caregiverHistory = bookings.where((b) => b.status.isFinished).toList();
        incomingChanges.add(incoming);
        caregiverBookingChanges.add(activeCaregiverBooking);
        caregiverHistoryChanges.add(caregiverHistory);
      }
    } catch (_) {
      // The connection screen and explicit user actions surface request errors.
    } finally {
      _refreshing = false;
    }
  }

  Future<Booking> _booking(Map<String, Object?> row) async {
    final data = Map<String, Object?>.from(row['payload'] as Map);
    final privateRows = await client.from('booking_private').select('booking_id,location').eq('booking_id', row['id'] as String).maybeSingle();
    final private = privateRows;
    final secretRows = caregiver == null
        ? null
        : await client.from('booking_secrets').select().eq('booking_id', row['id'] as String).maybeSingle();
    final loc = private?['location'] as Map?;
    data['location'] = loc == null
        ? const VisitLocation(label: 'Shared after acceptance', address: 'Address shown after accepting', latitude: 0, longitude: 0).toJson()
        : Map<String, Object?>.from(loc);
    data['clientCode'] = secretRows?['client_code'];
    data['safetyButtonId'] = secretRows?['safety_button_id'];
    data['status'] = row['status'];
    return Booking.fromJson(data);
  }

  VerificationStatus _verification(String value) => VerificationStatus.values.firstWhere(
    (v) => v.name.toLowerCase() == value.toLowerCase(),
    orElse: () => VerificationStatus.notSubmitted,
  );

  Future<AuthResult> signUpSeeker({required String name, required String email, required String password}) async {
    try {
      final result = await client.auth.signUp(email: email, password: password, data: {'role': 'seeker', 'full_name': name});
      if (result.session == null) return const AuthResult.failure('Account created. Verify your email, then sign in.');
      await refresh();
      return seeker == null ? const AuthResult.failure('Account created, but its profile is not ready yet. Sign in again.') : AuthResult.success(seeker!);
    } catch (e) { return AuthResult.failure(_message(e)); }
  }
  Future<AuthResult> signInSeeker({required String email, required String password}) async {
    try {
      await client.auth.signInWithPassword(email: email, password: password);
      await refresh();
      if (seeker == null) {
        await signOut();
        return const AuthResult.failure('This account is not registered as a care seeker.');
      }
      return AuthResult.success(seeker!);
    } catch (e) { return AuthResult.failure(_message(e)); }
  }
  Future<CaregiverAuthResult> signUpCaregiver({required String name, required String email, required String password, required Gender gender}) async {
    try {
      final result = await client.auth.signUp(email: email, password: password, data: {'role': 'caregiver', 'full_name': name, 'gender': gender.name});
      if (result.session == null) return const CaregiverAuthResult.failure('Account created. Verify your email, then sign in.');
      await refresh();
      return caregiver == null ? const CaregiverAuthResult.failure('Account created, but its profile is not ready yet. Sign in again.') : CaregiverAuthResult.success(caregiver!);
    } catch (e) { return CaregiverAuthResult.failure(_message(e)); }
  }
  Future<CaregiverAuthResult> signInCaregiver({required String email, required String password}) async {
    try {
      await client.auth.signInWithPassword(email: email, password: password);
      await refresh();
      if (caregiver == null) {
        await signOut();
        return const CaregiverAuthResult.failure('This account is not registered as a caregiver.');
      }
      return CaregiverAuthResult.success(caregiver!);
    } catch (e) { return CaregiverAuthResult.failure(_message(e)); }
  }
  Future<void> signOut() async {
    await client.auth.signOut();
    seeker = null; caregiver = null; activeSeekerBooking = null; activeCaregiverBooking = null; incoming = null;
    seekerChanges.add(null); caregiverChanges.add(null); seekerBookingChanges.add(null); caregiverBookingChanges.add(null); incomingChanges.add(null);
  }

  Future<Booking> submitRequest(HelpRequest request) async {
    final id = await client.rpc('create_care_request', params: {'p_payload': {
      'helpType': request.helpType.name, 'description': request.description,
      'checklist': request.checklist.toJson(), 'location': request.location.toJson(),
      'scheduledAt': request.scheduledAt.toIso8601String(), 'duration': request.duration.name,
      'durationMinutes': request.duration.minutes, 'genderFilter': request.genderFilter.name,
    }});
    await refresh();
    final found = activeSeekerBooking;
    if (found == null || found.id != id.toString()) throw StateError('Request was created but did not reload.');
    return found;
  }
  Future<Booking> retryWithGenderFilter(GenderFilter filter) async {
    final old = activeSeekerBooking;
    if (old == null) throw StateError('There is no active request to retry.');
    await actionResult('cancel', {'reason': CancellationReason.noMatch.name}, old.id);
    return submitRequest(HelpRequest(helpType: old.helpType, checklist: old.checklist, location: old.location, scheduledAt: old.scheduledAt, duration: old.duration, description: old.description, genderFilter: filter));
  }
  Future<Map<String, Object?>> actionResult(String action, [Map<String, Object?> data = const {}, String? bookingId]) async {
    final id = bookingId ?? activeSeekerBooking?.id ?? activeCaregiverBooking?.id ?? incoming?.id;
    if (id == null) throw StateError('No active request.');
    final result = await client.rpc('care_booking_action', params: {'p_booking_id': id, 'p_action': action, 'p_data': data});
    await refresh();
    return Map<String, Object?>.from(result as Map);
  }
  Future<void> action(String action, [Map<String, Object?> data = const {}]) async { await actionResult(action, data); }
  Future<void> updateGender(Gender gender) async { await client.from('caregiver_profiles').update({'gender': gender.name}).eq('user_id', client.auth.currentUser!.id); await refresh(); }
  Future<void> updateAvailability(CaregiverAvailability value) async { await client.from('caregiver_profiles').update({'availability': value.name}).eq('user_id', client.auth.currentUser!.id); await refresh(); }
  Future<void> submitCaregiverVerification() async {
    await client.rpc('submit_caregiver_verification');
    await refresh();
  }
  Future<void> completeSafetyModule() async {
    await client.rpc('complete_caregiver_safety_module');
    await refresh();
  }
  Future<void> saveRating(String table, Map<String, Object?> value) async { await client.rpc('save_care_rating', params: {'p_rating': value, 'p_kind': table}); }
  Future<void> saveFeedback(Map<String, Object?> value) async { await client.rpc('save_app_feedback', params: {'p_feedback': value}); }
  String _message(Object error) => error is AuthException ? error.message : error.toString();
}

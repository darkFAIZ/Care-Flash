import 'package:equatable/equatable.dart';

enum GrabRideStage { arranging, driverAssigned, inTransit, arrived }

class GrabRideInfo extends Equatable {
  final String rideId;
  final String driverName;
  final String vehiclePlate;
  final String vehicleModel;
  final String driverPhone;
  final int etaMinutes;
  final GrabRideStage stage;

  const GrabRideInfo({
    required this.rideId,
    required this.driverName,
    required this.vehiclePlate,
    required this.vehicleModel,
    required this.driverPhone,
    required this.etaMinutes,
    required this.stage,
  });

  GrabRideInfo copyWith({
    String? rideId,
    String? driverName,
    String? vehiclePlate,
    String? vehicleModel,
    String? driverPhone,
    int? etaMinutes,
    GrabRideStage? stage,
  }) {
    return GrabRideInfo(
      rideId: rideId ?? this.rideId,
      driverName: driverName ?? this.driverName,
      vehiclePlate: vehiclePlate ?? this.vehiclePlate,
      vehicleModel: vehicleModel ?? this.vehicleModel,
      driverPhone: driverPhone ?? this.driverPhone,
      etaMinutes: etaMinutes ?? this.etaMinutes,
      stage: stage ?? this.stage,
    );
  }

  @override
  List<Object?> get props => [
        rideId,
        driverName,
        vehiclePlate,
        vehicleModel,
        driverPhone,
        etaMinutes,
        stage,
      ];
}

class AcceptedTrip extends Equatable {
  final String bookingId;
  final String requestReference;
  final String careSeekerName;
  final String destinationAddress;
  final double latitude;
  final double longitude;
  final int durationMinutes;
  final int payoutIdr;
  final List<String> boundaryChecklist;
  final GrabRideInfo grabRide;

  const AcceptedTrip({
    required this.bookingId,
    required this.requestReference,
    required this.careSeekerName,
    required this.destinationAddress,
    required this.latitude,
    required this.longitude,
    required this.durationMinutes,
    required this.payoutIdr,
    required this.boundaryChecklist,
    required this.grabRide,
  });

  AcceptedTrip copyWith({
    String? bookingId,
    String? requestReference,
    String? careSeekerName,
    String? destinationAddress,
    double? latitude,
    double? longitude,
    int? durationMinutes,
    int? payoutIdr,
    List<String>? boundaryChecklist,
    GrabRideInfo? grabRide,
  }) {
    return AcceptedTrip(
      bookingId: bookingId ?? this.bookingId,
      requestReference: requestReference ?? this.requestReference,
      careSeekerName: careSeekerName ?? this.careSeekerName,
      destinationAddress: destinationAddress ?? this.destinationAddress,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      payoutIdr: payoutIdr ?? this.payoutIdr,
      boundaryChecklist: boundaryChecklist ?? this.boundaryChecklist,
      grabRide: grabRide ?? this.grabRide,
    );
  }

  @override
  List<Object?> get props => [
        bookingId,
        requestReference,
        careSeekerName,
        destinationAddress,
        latitude,
        longitude,
        durationMinutes,
        payoutIdr,
        boundaryChecklist,
        grabRide,
      ];
}

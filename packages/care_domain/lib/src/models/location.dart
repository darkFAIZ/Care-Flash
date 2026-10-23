/// A visit location. Coordinates are mocked until real maps/location is added.
///
/// Store only what matching and the accepted trip need. (FR-P-8, DC-P-3)
class VisitLocation {
  const VisitLocation({
    required this.label,
    required this.address,
    required this.latitude,
    required this.longitude,
  });

  final String label;
  final String address;
  final double latitude;
  final double longitude;

  VisitLocation copyWith({String? label, String? address}) => VisitLocation(
        label: label ?? this.label,
        address: address ?? this.address,
        latitude: latitude,
        longitude: longitude,
      );

  Map<String, Object?> toJson() => {
        'label': label,
        'address': address,
        'latitude': latitude,
        'longitude': longitude,
      };

  factory VisitLocation.fromJson(Map<String, Object?> json) => VisitLocation(
        label: json['label']! as String,
        address: json['address']! as String,
        latitude: (json['latitude']! as num).toDouble(),
        longitude: (json['longitude']! as num).toDouble(),
      );

  /// Mock locations offered in the demo. TODO(team): replace with a map picker.
  static const List<VisitLocation> mockPresets = [
    VisitLocation(
      label: 'Community library',
      address: 'Jl. Kampus Raya No. 1, Depok',
      latitude: -6.3628,
      longitude: 106.8270,
    ),
    VisitLocation(
      label: 'Boarding house',
      address: 'Jl. Margonda Raya No. 42, Depok',
      latitude: -6.3728,
      longitude: 106.8317,
    ),
    VisitLocation(
      label: 'Residential apartment',
      address: 'Jl. Akses UI No. 7, Depok',
      latitude: -6.3600,
      longitude: 106.8260,
    ),
  ];
}

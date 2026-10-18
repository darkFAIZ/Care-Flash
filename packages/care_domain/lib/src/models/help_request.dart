import '../enums.dart';
import 'boundary_checklist.dart';
import 'location.dart';

/// The details collected before a request is submitted. (FR-CS-4 to FR-CS-7)
class HelpRequest {
  const HelpRequest({
    required this.helpType,
    required this.checklist,
    required this.location,
    required this.scheduledAt,
    required this.duration,
    this.description,
    this.genderFilter = GenderFilter.both,
  });

  final HelpType helpType;
  final String? description;
  final BoundaryChecklist checklist;
  final VisitLocation location;
  final DateTime scheduledAt;
  final VisitDuration duration;
  final GenderFilter genderFilter;

  HelpRequest copyWith({
    HelpType? helpType,
    String? description,
    BoundaryChecklist? checklist,
    VisitLocation? location,
    DateTime? scheduledAt,
    VisitDuration? duration,
    GenderFilter? genderFilter,
  }) {
    return HelpRequest(
      helpType: helpType ?? this.helpType,
      description: description ?? this.description,
      checklist: checklist ?? this.checklist,
      location: location ?? this.location,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      duration: duration ?? this.duration,
      genderFilter: genderFilter ?? this.genderFilter,
    );
  }
}

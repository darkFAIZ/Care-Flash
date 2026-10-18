import 'package:care_core/care_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The request being built across the request-flow screens. (FR-CS-4 to FR-CS-8)
///
/// Every screen in the flow updates one field; the final screen submits it.
class RequestDraft {
  const RequestDraft({
    this.helpType,
    this.description = '',
    this.checklist,
    this.location,
    this.scheduledAt,
    this.duration,
    this.genderFilter = GenderFilter.both,
  });

  final HelpType? helpType;
  final String description;
  final BoundaryChecklist? checklist;
  final VisitLocation? location;
  final DateTime? scheduledAt;
  final VisitDuration? duration;
  final GenderFilter genderFilter;

  /// True once every required field has been chosen. (FR-CS-8)
  bool get canSubmit =>
      helpType != null &&
      checklist != null &&
      location != null &&
      scheduledAt != null &&
      duration != null;

  RequestDraft copyWith({
    HelpType? helpType,
    String? description,
    BoundaryChecklist? checklist,
    VisitLocation? location,
    DateTime? scheduledAt,
    VisitDuration? duration,
    GenderFilter? genderFilter,
  }) {
    return RequestDraft(
      helpType: helpType ?? this.helpType,
      description: description ?? this.description,
      checklist: checklist ?? this.checklist,
      location: location ?? this.location,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      duration: duration ?? this.duration,
      genderFilter: genderFilter ?? this.genderFilter,
    );
  }

  /// Builds the domain [HelpRequest] submitted to the platform. (FR-CS-4)
  HelpRequest toHelpRequest() => HelpRequest(
        helpType: helpType!,
        description: description.trim().isEmpty ? null : description.trim(),
        checklist: checklist!,
        location: location!,
        scheduledAt: scheduledAt!,
        duration: duration!,
        genderFilter: genderFilter,
      );
}

/// Holds the in-progress [RequestDraft]; reset when a new request starts.
class RequestDraftController extends Notifier<RequestDraft> {
  @override
  RequestDraft build() => const RequestDraft();

  void reset() => state = const RequestDraft();

  void setHelpType(HelpType value) => state = state.copyWith(helpType: value);

  void setDescription(String value) =>
      state = state.copyWith(description: value);

  void setChecklist(BoundaryChecklist value) =>
      state = state.copyWith(checklist: value);

  void setLocation(VisitLocation value) =>
      state = state.copyWith(location: value);

  void setSchedule(DateTime value) => state = state.copyWith(scheduledAt: value);

  void setDuration(VisitDuration value) =>
      state = state.copyWith(duration: value);

  void setGenderFilter(GenderFilter value) =>
      state = state.copyWith(genderFilter: value);
}

final requestDraftProvider =
    NotifierProvider<RequestDraftController, RequestDraft>(
  RequestDraftController.new,
);

import '../enums.dart';

/// Tasks the care seeker allows or does not allow during the visit.
///
/// Also carries the off-limit rooms section from the team's sketch
/// (AGENTS.md §6) so the boundary checklist is one object. (FR-CS-5)
class BoundaryChecklist {
  const BoundaryChecklist({
    this.allowedTasks = const [],
    this.disallowedTasks = const [],
    this.offLimitRooms = const [],
    this.offLimitNote,
  });

  final List<String> allowedTasks;
  final List<String> disallowedTasks;
  final List<OffLimitRoom> offLimitRooms;
  final String? offLimitNote;

  BoundaryChecklist copyWith({
    List<String>? allowedTasks,
    List<String>? disallowedTasks,
    List<OffLimitRoom>? offLimitRooms,
    String? offLimitNote,
  }) {
    return BoundaryChecklist(
      allowedTasks: allowedTasks ?? this.allowedTasks,
      disallowedTasks: disallowedTasks ?? this.disallowedTasks,
      offLimitRooms: offLimitRooms ?? this.offLimitRooms,
      offLimitNote: offLimitNote ?? this.offLimitNote,
    );
  }

  Map<String, Object?> toJson() => {
        'allowedTasks': allowedTasks,
        'disallowedTasks': disallowedTasks,
        'offLimitRooms': offLimitRooms.map((room) => room.name).toList(),
        'offLimitNote': offLimitNote,
      };

  factory BoundaryChecklist.fromJson(Map<String, Object?> json) {
    return BoundaryChecklist(
      allowedTasks:
          (json['allowedTasks'] as List<Object?>? ?? const []).cast<String>(),
      disallowedTasks:
          (json['disallowedTasks'] as List<Object?>? ?? const []).cast<String>(),
      offLimitRooms: (json['offLimitRooms'] as List<Object?>? ?? const [])
          .map((name) => OffLimitRoom.values.byName(name! as String))
          .toList(),
      offLimitNote: json['offLimitNote'] as String?,
    );
  }

  /// Suggested tasks shown when the checklist is first opened. (FR-CS-5)
  static const List<String> standardAllowedTasks = [
    'Prepare simple meals',
    'Help with light housework',
    'Accompany to the pharmacy',
    'Company / conversation',
    'Remind me to take medicine',
  ];

  static const List<String> standardDisallowedTasks = [
    'Medical or clinical treatment',
    'Heavy lifting',
    'Personal hygiene assistance',
    'Handling money or valuables',
  ];

  /// A checklist with the standard tasks pre-selected.
  static const BoundaryChecklist suggested = BoundaryChecklist(
    allowedTasks: standardAllowedTasks,
    disallowedTasks: standardDisallowedTasks,
  );
}

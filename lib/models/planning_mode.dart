enum PlanningMode {
  quickDecision('quick_decision', requiresPremium: false),
  dateNight('date_night', requiresPremium: true),
  localEvents('local_events', requiresPremium: true),
  trip('trip', requiresPremium: true);

  const PlanningMode(this.wireName, {required this.requiresPremium});

  final String wireName;
  final bool requiresPremium;

  static PlanningMode fromWireName(String? value) {
    return PlanningMode.values.firstWhere(
      (mode) => mode.wireName == value,
      orElse: () => PlanningMode.quickDecision,
    );
  }
}

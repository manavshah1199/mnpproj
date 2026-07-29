/// How dangerous the weather is. Order matters: safe < caution < danger.
enum RiskLevel { safe, caution, danger }
/// The engine's answer: one level, plus WHY and WHAT TO DO.
class RiskResult {
  final RiskLevel level;
  final List<String> reasons;   // why it's this level
  final List<String> actions;   // what the user should do
  final double? feelsLike;      // the temperature that mattered

  RiskResult({
    required this.level,
    this.reasons = const [],
    this.actions = const [],
    this.feelsLike,
  });

  /// True on a Danger day — later this triggers the check-in safety net.
  bool get isDangerousDay => level == RiskLevel.danger;
}
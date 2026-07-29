import '../models/user_profile.dart';
import '../models/weather_snapshot.dart';

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

class RiskEngine {
  static RiskResult assess(WeatherSnapshot weather, UserProfile profile) {
    final feels = weather.feelsLike;
    // the "feels like" temp from the getter
    final reasons = <String>[];
    // empty list we'll fill with WHY
    final actions = <String>[];
    // empty list we'll fill with WHAT TO DO
    RiskLevel level = RiskLevel.safe;
    // start optimistic, raise as needed
        // --- HEAT ---
    if (feels != null && feels >= 80) {
      if (feels >= 103) {
        level = RiskLevel.danger;
        reasons.add('Heat index ${feels.round()}°F — NWS "Danger" range.');
        actions.add('Stay somewhere cool; watch for dizziness or nausea.');
      } else if (feels >= 90) {
        level = RiskLevel.caution;
        reasons.add('Heat index ${feels.round()}°F — take rest breaks.');
        actions.add('Hydrate often and rest in shade or AC.');
      } else {
        level = RiskLevel.caution;
        reasons.add('Heat index ${feels.round()}°F — basic precautions.');
        actions.add('Drink water and avoid peak-sun exertion.');
      }
        // --- Personal escalation: same weather is MORE dangerous for some people ---
      if (!profile.hasAC && feels >= 90) {
        level = _escalate(level);
        reasons.add('No air conditioning during high heat.');
        actions.add('Consider a cooling center (see Nearest Help).');
      }
      if (profile.age != null && profile.age! >= 65 && feels >= 90) {
        level = _escalate(level);
        reasons.add('Age 65+ raises heat-illness risk.');
      }
      if (profile.conditions.isNotEmpty && feels >= 90) {
        level = _escalate(level);
        reasons.add('A health condition on file increases heat sensitivity.');
      }
    }
          // --- If nothing raised the level, say so plainly ---
    if (level == RiskLevel.safe && reasons.isEmpty) {
      reasons.add('No dangerous heat right now.');
      actions.add('No special precautions needed. Check back later.');
    }

    return RiskResult(
      level: level,
      reasons: reasons,
      actions: actions,
      feelsLike: feels,
    );
  }
    /// Bump a level up one step, capped at danger.
  static RiskLevel _escalate(RiskLevel level) {
    if (level == RiskLevel.caution) return RiskLevel.danger;
    if (level == RiskLevel.danger) return RiskLevel.danger;
    return RiskLevel.caution;
  }
}
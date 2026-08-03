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
    // --- COLD ---
    if (feels != null && feels <= 32) {
      if (feels <= 0) {
        level = _worst(level, RiskLevel.danger);
        reasons.add('Wind chill ${feels.round()}°F — frostbite in minutes.');
        actions.add('Avoid going outside; cover all exposed skin.');
      } else if (feels <= 15) {
        level = _worst(level, RiskLevel.danger);
        reasons.add('Wind chill ${feels.round()}°F — frostbite risk.');
        actions.add('Limit time outdoors; wear hat, gloves, and layers.');
      } else {
        level = _worst(level, RiskLevel.caution);
        reasons.add('Wind chill ${feels.round()}°F — dress warm.');
        actions.add('Wear layers and keep extremities covered.');
      }

      // Personal escalation for cold
      if (!profile.hasHeating && feels <= 32) {
        level = _escalate(level);
        reasons.add('No reliable heating during freezing conditions.');
        actions.add('Consider a warming center (see Nearest Help).');
      }
      if (profile.age != null && profile.age! >= 65 && feels <= 15) {
        level = _escalate(level);
        reasons.add('Age 65+ raises hypothermia risk.');
      }
    }
        // --- WEATHER ALERTS (drivers care most) ---
    for (final alert in weather.alerts) {
      final event = alert.event.toLowerCase();
      final isRoadHazard = event.contains('flood') ||
          event.contains('storm') ||
          event.contains('ice') ||
          event.contains('snow');

      final sev = alert.severity.toLowerCase();
      if (sev == 'severe' || sev == 'extreme') {
        level = _worst(level, RiskLevel.danger);
      } else {
        level = _worst(level, RiskLevel.caution);
      }
      reasons.add('Active alert: ${alert.event}.');

      // Driver mode gets road-specific advice — same engine, different emphasis.
      if (profile.mode == Mode.driver && isRoadHazard) {
        level = RiskLevel.danger;
        actions.add('${alert.event}: avoid flooded roads — "Turn Around, Don\'t Drown."');
        actions.add('Delay non-essential driving until it clears.');
      } else {
        actions.add('Follow official guidance for: ${alert.event}.');
      }
    }
          // --- If nothing raised the level, say so plainly ---
    if (level == RiskLevel.safe && reasons.isEmpty) {
      reasons.add('No dangerous heat, cold, or active alerts right now.');
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

  /// Return the higher (worse) of two levels.
 static RiskLevel _worst(RiskLevel a, RiskLevel b) => a.index >= b.index ? a : b;

 /// OSHA-style work/rest guidance for outdoor workers.
/// [sessionMinutes] = how long they've been working outside so far.
static WorkRest workRest(double? feels, int sessionMinutes) {
  if (feels == null || feels < 90) {
    return WorkRest(applies: false); // not hot enough to force breaks
  }

  int work;
  int rest;
  String note;
  if (feels >= 100) {
    work = 15;
    rest = 45;
    note = 'Extreme heat: 15 min work / 45 min rest.';
  } else if (feels >= 95) {
    work = 30;
    rest = 30;
    note = 'High heat: 30 min work / 30 min rest.';
  } else {
    work = 45;
    rest = 15;
    note = 'Elevated heat: 45 min work / 15 min rest.';
  }

  final cycle = work + rest;
  final posInCycle = sessionMinutes % cycle;
  final breakDue = posInCycle >= work;
  final untilBreak = breakDue ? 0 : work - posInCycle;

  return WorkRest(
    applies: true,
    workMinutes: work,
    restMinutes: rest,
    note: note,
    breakDue: breakDue,
    minutesUntilBreak: untilBreak,
  );
}
}

/// Outdoor-worker break guidance produced by RiskEngine.workRest().
class WorkRest {
  final bool applies; // false when it's not hot enough to matter
  final int workMinutes;
  final int restMinutes;
  final String note;
  final bool breakDue; // is a break due right now?
  final int minutesUntilBreak;

  WorkRest({
    this.applies = false,
    this.workMinutes = 0,
    this.restMinutes = 0,
    this.note = '',
    this.breakDue = false,
    this.minutesUntilBreak = 0,
  });
}
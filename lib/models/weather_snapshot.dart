/// One active weather alert from the NWS (e.g. a Flash Flood Warning).
class WeatherAlert {
  final String event;      // "Flash Flood Warning"
  final String severity;   // "Minor" | "Moderate" | "Severe" | "Extreme"
  final String headline;

  WeatherAlert({
    this.event = '',
    this.severity = '',
    this.headline = '',
  });
}

/// One block of the NWS 7-day forecast, e.g. "Saturday" or "Saturday Night".
class ForecastPeriod {
  final String name;          // "Tonight", "Saturday", ...
  final bool isDaytime;
  final int? tempF;           // high for day periods, low for night periods
  final String shortForecast; // "Chance Rain Showers"
  final int? precipChance;    // %

  ForecastPeriod({
    required this.name,
    required this.isDaytime,
    this.tempF,
    this.shortForecast = '',
    this.precipChance,
  });
}

/// The kinds of dangerous weather the app gives specific help for.
enum Hazard { heat, cold, snow, rain, storm, flood, wind }

extension HazardLabel on Hazard {
  String get label {
    switch (this) {
      case Hazard.heat:
        return 'Heat';
      case Hazard.cold:
        return 'Cold';
      case Hazard.snow:
        return 'Snow / ice';
      case Hazard.rain:
        return 'Rain';
      case Hazard.storm:
        return 'Storms';
      case Hazard.flood:
        return 'Flooding';
      case Hazard.wind:
        return 'High wind';
    }
  }
}

/// A single, normalized reading of the weather at one place and time.
class WeatherSnapshot {
  final double? tempF;        // air temperature °F (null if unknown)
  final double? heatIndexF;   // "feels like" in heat
  final double? windChillF;   // "feels like" in cold
  final int? humidity;        // %
  final double? windMph;
  final String shortForecast; // e.g. "Sunny"
  final List<WeatherAlert> alerts;
  final List<ForecastPeriod> forecast; // upcoming week, soonest first
  final DateTime? observedAt;
  final String locationName;  // e.g. "Edison, NJ"
  final double? lat;          // where this reading is for (centers the map)
  final double? lon;
  final bool isSample;        // true if this is fallback data, not live
  final bool isSimulated;     // true if this is demo/simulated data

  WeatherSnapshot({
    this.tempF,
    this.heatIndexF,
    this.windChillF,
    this.humidity,
    this.windMph,
    this.shortForecast = '',
    this.alerts = const [],
    this.forecast = const [],
    this.observedAt,
    this.locationName = '',
    this.lat,
    this.lon,
    this.isSample = false,
    this.isSimulated = false,
  });

  /// The temperature that actually matters for risk:
  /// heat index when hot, wind chill when cold, otherwise plain temp.
  double? get feelsLike {
    if (tempF == null) return null;
    if (tempF! >= 80 && heatIndexF != null) return heatIndexF;
    if (tempF! <= 50 && windChillF != null) return windChillF;
    return tempF;
  }

  /// Which hazards are happening now or forecast for today.
  /// Empty means calm weather.
  Set<Hazard> get hazards {
    final found = <Hazard>{};
    final feels = feelsLike;
    if (feels != null && feels >= 90) found.add(Hazard.heat);
    if (feels != null && feels <= 32) found.add(Hazard.cold);
    if (windMph != null && windMph! >= 30) found.add(Hazard.wind);

    // Read the words: current conditions, today's forecast, and alert names.
    final text = [
      shortForecast,
      if (forecast.isNotEmpty) forecast.first.shortForecast,
      for (final a in alerts) a.event,
    ].join(' ').toLowerCase();

    if (_hasAny(text, ['snow', 'blizzard', 'sleet', 'ice', 'freezing rain'])) {
      found.add(Hazard.snow);
    }
    if (_hasAny(text, ['thunder', 'storm', 'tornado', 'hurricane', 'tropical'])) {
      found.add(Hazard.storm);
    }
    if (text.contains('flood')) found.add(Hazard.flood);
    if (_hasAny(text, ['rain', 'shower', 'drizzle'])) found.add(Hazard.rain);
    if (_hasAny(text, ['wind advisory', 'high wind', 'gale'])) {
      found.add(Hazard.wind);
    }
    if (text.contains('heat')) found.add(Hazard.heat);
    return found;
  }

  static bool _hasAny(String text, List<String> words) =>
      words.any(text.contains);
}

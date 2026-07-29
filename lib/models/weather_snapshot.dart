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

/// A single, normalized reading of the weather at one place and time.
class WeatherSnapshot {
  final double? tempF;        // air temperature °F (null if unknown)
  final double? heatIndexF;   // "feels like" in heat
  final double? windChillF;   // "feels like" in cold
  final int? humidity;        // %
  final double? windMph;
  final String shortForecast; // e.g. "Sunny"
  final List<WeatherAlert> alerts;
  final DateTime? observedAt;
  final String locationName;  // e.g. "Edison, NJ"
  final bool isSample;        // true if this is fallback data, not live

  WeatherSnapshot({
    this.tempF,
    this.heatIndexF,
    this.windChillF,
    this.humidity,
    this.windMph,
    this.shortForecast = '',
    this.alerts = const [],
    this.observedAt,
    this.locationName = '',
    this.isSample = false,
  });
  /// The temperature that actually matters for risk:
  /// heat index when hot, wind chill when cold, otherwise plain temp.
  double? get feelsLike {
    if (tempF == null) return null;
    if (tempF! >= 80 && heatIndexF != null) return heatIndexF;
    if (tempF! <= 50 && windChillF != null) return windChillF;
    return tempF;
  }
}
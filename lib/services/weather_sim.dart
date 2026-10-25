import '../models/weather_snapshot.dart';

/// The demo scenarios you can force.
enum SimPreset {
  off, safe, hotCaution, hotDanger, extremeHeat, rain, thunderstorm, snow,
  freezing, flood
}

/// Demo-only weather override. Not real app logic — it just swaps in fake
/// weather when a preset is active, so you can show every risk level on demand.
class WeatherSim {
  // The active preset. In-memory, so it resets when the app restarts (fine for demos).
  static SimPreset active = SimPreset.off;

  static String label(SimPreset p) {
    switch (p) {
      case SimPreset.off:
        return 'Off — use live weather';
      case SimPreset.safe:
        return 'Mild — Safe';
      case SimPreset.hotCaution:
        return 'Hot — Caution';
      case SimPreset.hotDanger:
        return 'Hot — Danger';
      case SimPreset.extremeHeat:
        return 'Extreme heat';
      case SimPreset.rain:
        return 'Heavy rain';
      case SimPreset.thunderstorm:
        return 'Severe thunderstorm';
      case SimPreset.snow:
        return 'Snowstorm';
      case SimPreset.freezing:
        return 'Freezing — Danger';
      case SimPreset.flood:
        return 'Flash Flood alert';
    }
  }

  /// If a preset is active, return fake weather; otherwise pass the real one through.
  static WeatherSnapshot apply(WeatherSnapshot real) {
    // Keep the real place (and its forecast) so the map and week still make sense.
    WeatherSnapshot sim({
      double? tempF,
      double? heatIndexF,
      double? windChillF,
      int? humidity,
      double? windMph,
      required String shortForecast,
      List<WeatherAlert> alerts = const [],
    }) =>
        WeatherSnapshot(
          tempF: tempF,
          heatIndexF: heatIndexF,
          windChillF: windChillF,
          humidity: humidity,
          windMph: windMph,
          shortForecast: shortForecast,
          alerts: alerts,
          forecast: real.forecast,
          locationName: real.locationName,
          lat: real.lat,
          lon: real.lon,
          isSimulated: true,
        );

    switch (active) {
      case SimPreset.off:
        return real;
      case SimPreset.safe:
        return sim(
            tempF: 72, humidity: 45, windMph: 5,
            shortForecast: 'Sunny (simulated)');
      case SimPreset.hotCaution:
        return sim(
            tempF: 84, heatIndexF: 85, humidity: 55,
            shortForecast: 'Hot (simulated)');
      case SimPreset.hotDanger:
        return sim(
            tempF: 94, heatIndexF: 96, humidity: 65,
            shortForecast: 'Very hot (simulated)');
      case SimPreset.extremeHeat:
        return sim(
            tempF: 100, heatIndexF: 106, humidity: 60,
            shortForecast: 'Dangerous heat (simulated)',
            alerts: [
              WeatherAlert(
                  event: 'Excessive Heat Warning',
                  severity: 'Severe',
                  headline: 'Dangerous heat expected'),
            ]);
      case SimPreset.rain:
        return sim(
            tempF: 61, humidity: 95, windMph: 12,
            shortForecast: 'Heavy Rain (simulated)');
      case SimPreset.thunderstorm:
        return sim(
            tempF: 78, humidity: 85, windMph: 35,
            shortForecast: 'Thunderstorms (simulated)',
            alerts: [
              WeatherAlert(
                  event: 'Severe Thunderstorm Warning',
                  severity: 'Severe',
                  headline: 'Damaging winds and falling trees possible'),
            ]);
      case SimPreset.snow:
        return sim(
            tempF: 26, windChillF: 15, windMph: 18,
            shortForecast: 'Heavy Snow (simulated)',
            alerts: [
              WeatherAlert(
                  event: 'Winter Storm Warning',
                  severity: 'Severe',
                  headline: '8 to 12 inches of snow expected'),
            ]);
      case SimPreset.freezing:
        return sim(
            tempF: 12, windChillF: 5, windMph: 20,
            shortForecast: 'Frigid (simulated)');
      case SimPreset.flood:
        return sim(
            tempF: 68, humidity: 92, windMph: 15,
            shortForecast: 'Heavy rain (simulated)',
            alerts: [
              WeatherAlert(
                  event: 'Flash Flood Warning',
                  severity: 'Severe',
                  headline: 'Flash flooding likely'),
            ]);
    }
  }
}

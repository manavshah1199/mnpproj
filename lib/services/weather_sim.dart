import '../models/weather_snapshot.dart';

/// The demo scenarios you can force.
enum SimPreset { off, safe, hotCaution, hotDanger, extremeHeat, freezing, flood }

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
      case SimPreset.freezing:
        return 'Freezing — Danger';
      case SimPreset.flood:
        return 'Flash Flood alert';
    }
  }

  /// If a preset is active, return fake weather; otherwise pass the real one through.
  static WeatherSnapshot apply(WeatherSnapshot real) {
    final where = real.locationName;
    switch (active) {
      case SimPreset.off:
        return real;
      case SimPreset.safe:
        return WeatherSnapshot(
            tempF: 72, humidity: 45, windMph: 5,
            shortForecast: 'Sunny (simulated)',
            locationName: where, isSimulated: true);
      case SimPreset.hotCaution:
        return WeatherSnapshot(
            tempF: 84, heatIndexF: 85, humidity: 55,
            shortForecast: 'Hot (simulated)',
            locationName: where, isSimulated: true);
      case SimPreset.hotDanger:
        return WeatherSnapshot(
            tempF: 94, heatIndexF: 96, humidity: 65,
            shortForecast: 'Very hot (simulated)',
            locationName: where, isSimulated: true);
      case SimPreset.extremeHeat:
        return WeatherSnapshot(
            tempF: 100, heatIndexF: 106, humidity: 60,
            shortForecast: 'Dangerous heat (simulated)',
            locationName: where, isSimulated: true);
      case SimPreset.freezing:
        return WeatherSnapshot(
            tempF: 12, windChillF: 5, windMph: 20,
            shortForecast: 'Frigid (simulated)',
            locationName: where, isSimulated: true);
      case SimPreset.flood:
        return WeatherSnapshot(
            tempF: 68, humidity: 92, windMph: 15,
            shortForecast: 'Heavy rain (simulated)',
            locationName: where,
            alerts: [
              WeatherAlert(
                  event: 'Flash Flood Warning',
                  severity: 'Severe',
                  headline: 'Flash flooding likely'),
            ],
            isSimulated: true);
    }
  }
}
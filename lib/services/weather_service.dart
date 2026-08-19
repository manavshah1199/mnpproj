import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/weather_snapshot.dart';

/// Fetches live weather from the National Weather Service (api.weather.gov).
class WeatherService {
  static const _base = 'https://api.weather.gov';

  // Celsius -> Fahrenheit (NWS returns metric).
  static double? _cToF(num? c) => c == null ? null : c * 9 / 5 + 32;

  /// Get live weather for a lat/lon. Returns labeled sample data on any failure.
  static Future<WeatherSnapshot> fetchWeather(double lat, double lon) async {
    try {
      final point =
          '${lat.toStringAsFixed(4)},${lon.toStringAsFixed(4)}';

      // Step 1: point metadata (which station covers this spot + city name).
      final pointsData = await _getJson('$_base/points/$point');
      final props = pointsData['properties'];
      final rel = props['relativeLocation']?['properties'];
      final locationName =
          rel == null ? 'Your area' : '${rel['city']}, ${rel['state']}';

      // Step 2: nearest station -> its latest observation.
      final stationsData = await _getJson(props['observationStations']);
      final stationId =
          stationsData['features'][0]['properties']['stationIdentifier'];
      final obs =
          await _getJson('$_base/stations/$stationId/observations/latest');
      final o = obs['properties'];

      // Step 3: active alerts for this point.
      final alertsData = await _getJson('$_base/alerts/active?point=$point');
      final alerts = <WeatherAlert>[];
      for (final f in (alertsData['features'] as List)) {
        final p = f['properties'];
        alerts.add(WeatherAlert(
          event: p['event'] ?? '',
          severity: p['severity'] ?? '',
          headline: p['headline'] ?? '',
        ));
      }

      // Wind speed comes in km/h; convert to mph.
      double? windMph;
      final ws = o['windSpeed']?['value'];
      if (ws != null) windMph = (ws as num) * 0.621371;

      return WeatherSnapshot(
        tempF: _cToF(o['temperature']?['value']),
        heatIndexF: _cToF(o['heatIndex']?['value']),
        windChillF: _cToF(o['windChill']?['value']),
        humidity: (o['relativeHumidity']?['value'] as num?)?.round(),
        windMph: windMph,
        shortForecast: o['textDescription'] ?? '',
        alerts: alerts,
        locationName: locationName,
        observedAt: DateTime.tryParse(o['timestamp'] ?? ''),
      );
    } catch (e) {
      // Network/API problem -> clearly-labeled sample data so the app still runs.
      return WeatherSnapshot(
        tempF: 88,
        heatIndexF: 92,
        humidity: 62,
        shortForecast: 'Sample data (live weather unavailable)',
        locationName: 'Middlesex/Union County, NJ',
        isSample: true,
      );
    }
  }

  // Fetch a URL and return its JSON as a Map. Throws if the request fails.
  static Future<Map<String, dynamic>> _getJson(String url) async {
    final res = await http.get(
      Uri.parse(url),
      headers: {'Accept': 'application/geo+json'},
    );
    if (res.statusCode != 200) {
      throw Exception('NWS request failed: ${res.statusCode}');
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }
}

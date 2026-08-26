import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/weather_snapshot.dart';
import 'dart:math';

/// Fetches live weather from the National Weather Service (api.weather.gov).
class WeatherService {
  static const _base = 'https://api.weather.gov';

  // Celsius -> Fahrenheit (NWS returns metric).
  static double? _cToF(num? c) => c == null ? null : c * 9 / 5 + 32;

  // Rothfusz heat-index formula. Inputs °F and RH%. Only valid at T >= 80°F.
  static double? _computeHeatIndex(double? tempF, int? humidity) {
    if (tempF == null || humidity == null || tempF < 80) return null;
    final t = tempF;
    final r = humidity.toDouble();
    return -42.379 +
        2.04901523 * t +
        10.14333127 * r -
        0.22475541 * t * r -
        0.00683783 * t * t -
        0.05481717 * r * r +
        0.00122874 * t * t * r +
        0.00085282 * t * r * r -
        0.00000199 * t * t * r * r;
  }

  // NWS wind-chill formula. Inputs °F and mph. Only valid at T <= 50°F and wind > 3 mph.
  static double? _computeWindChill(double? tempF, double? windMph) {
    if (tempF == null || windMph == null || tempF > 50 || windMph <= 3) {
      return null;
    }
    final v = pow(windMph, 0.16).toDouble();
    return 35.74 + 0.6215 * tempF - 35.75 * v + 0.4275 * tempF * v;
  }

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

      final tempF = _cToF(o['temperature']?['value']);
      final humidity = (o['relativeHumidity']?['value'] as num?)?.round();

      // Prefer the NWS value; compute it ourselves if the NWS left it blank.
      final heatIndexF =
          _cToF(o['heatIndex']?['value']) ?? _computeHeatIndex(tempF, humidity);
      final windChillF =
          _cToF(o['windChill']?['value']) ?? _computeWindChill(tempF, windMph);

      return WeatherSnapshot(
        tempF: tempF,
        heatIndexF: heatIndexF,
        windChillF: windChillF,
        humidity: humidity,
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
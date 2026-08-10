import 'package:flutter/material.dart';
import 'models/user_profile.dart';
import 'models/weather_snapshot.dart';
import 'services/risk_engine.dart';


void main() {
  runApp(const WeatherSafeApp());
}

/// The root of the whole app.
class WeatherSafeApp extends StatelessWidget {
  const WeatherSafeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WeatherSafe',
      home: const HomeScreen(),
    );
  }
}

/// Picks a color for each risk level.
Color riskColor(RiskLevel level) {
  switch (level) {
    case RiskLevel.safe:
      return Colors.green.shade600;
    case RiskLevel.caution:
      return Colors.orange.shade800;
    case RiskLevel.danger:
      return Colors.red.shade700;
  }
}

/// The "Today's Risk" screen.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // --- TEST DATA (temporary) ---
    final profile = UserProfile(
      mode: Mode.resident,
      age: 78,
      hasAC: false,
      conditions: ['heart'],
    );
    final weather = WeatherSnapshot(
      tempF: 94,
      heatIndexF: 96,
      humidity: 65,
      locationName: 'Edison, NJ',
    );

    final result = RiskEngine.assess(weather, profile);

    return Scaffold(
      appBar: AppBar(title: const Text('Today\'s Risk')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // --- Colored risk banner ---
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: riskColor(result.level),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  result.level.name.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  '${weather.locationName} · feels like ${result.feelsLike?.round()}°F',
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          const Text(
            'Why',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          for (final reason in result.reasons) Text('• $reason'),
          const SizedBox(height: 20),

          const Text(
            'What to do',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          for (final action in result.actions) Text('• $action'),
        ],
      ),
    );
  }
}


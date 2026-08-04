import 'package:flutter/material.dart';
import 'models/user_profile.dart';
import 'models/weather_snapshot.dart';
import 'services/risk_engine.dart';
import 'screens/home_screen.dart';

class WeatherGuardApp extends StatelessWidget {
  const WeatherGuardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WeatherGuard',
      theme: ThemeData(
        colorSchemeSeed: Colors.deepPurple,
        useMaterial3: true,
      ),
      home: const AppState(),
    );
  }
}

class AppState extends StatefulWidget {
  const AppState({super.key});

  @override
  State<AppState> createState() => _AppStateState();
}

class _AppStateState extends State<AppState> {
  // TODO: replace with a real onboarding flow (Module 4).
  UserProfile _profile = UserProfile(
    mode: Mode.outdoorWorker,
    age: 45,
    hasAC: true,
    hasHeating: true,
  );

  // TODO: replace with a live NWS API call (Module 5).
  WeatherSnapshot _weather = WeatherSnapshot(
    tempF: 96,
    heatIndexF: 104,
    humidity: 55,
    windMph: 6,
    shortForecast: 'Sunny',
    locationName: 'Scotch Plains, NJ',
    observedAt: DateTime.now(),
    isSample: true,
    alerts: [
      WeatherAlert(
        event: 'Excessive Heat Warning',
        severity: 'Severe',
        headline: 'Dangerous heat expected through this evening.',
      ),
    ],
  );

  void updateProfile(UserProfile newProfile) {
    setState(() {
      _profile = newProfile;
    });
  }

  void updateWeather(WeatherSnapshot newWeather) {
    setState(() {
      _weather = newWeather;
    });
  }

  @override
  Widget build(BuildContext context) {
    final result = RiskEngine.assess(_weather, _profile);

    return HomeScreen(
      profile: _profile,
      weather: _weather,
      result: result,
      onProfileChanged: updateProfile,
    );
  }
}
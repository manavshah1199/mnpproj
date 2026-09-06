import 'package:flutter/material.dart';
import 'models/user_profile.dart';
import 'models/weather_snapshot.dart';
import 'services/location_service.dart';
import 'services/risk_engine.dart';
import 'services/storage_service.dart';
import 'services/weather_service.dart';
import 'services/weather_sim.dart';
import 'screens/main_scaffold.dart';
import 'screens/onboarding_screen.dart';

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
      builder: (context, child) {
        final mq = MediaQuery.of(context);
        // Text is at least 1.1x, honoring the user's setting up to 1.5x.
        return MediaQuery(
          data: mq.copyWith(
            textScaler: mq.textScaler.clamp(
              minScaleFactor: 1.1,
              maxScaleFactor: 1.5,
            ),
          ),
          child: child!,
        );
      },
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
  UserProfile? _profile;
  bool _profileLoading = true;

  WeatherSnapshot? _weather;
  bool _weatherLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadWeather();
  }

  Future<void> _loadProfile() async {
    final saved = await StorageService.loadProfile();
    if (!mounted) return;
    setState(() {
      _profile = saved;
      _profileLoading = false;
    });
  }

  Future<void> _loadWeather() async {
    setState(() => _weatherLoading = true);
    final loc = await LocationService.getLocation();
    final weather =
        WeatherSim.apply(await WeatherService.fetchWeather(loc.lat, loc.lon));
    if (!mounted) return;
    setState(() {
      _weather = weather;
      _weatherLoading = false;
    });
  }

  void updateProfile(UserProfile newProfile) {
    setState(() => _profile = newProfile);
    StorageService.saveProfile(newProfile);
  }

  void resetProfile() {
    setState(() => _profile = null);
  }

  @override
  Widget build(BuildContext context) {
    if (_profileLoading || _weatherLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final profile = _profile;
    if (profile == null) {
      return OnboardingScreen(onComplete: updateProfile);
    }

    final weather = _weather!;
    final result = RiskEngine.assess(weather, profile);

    return MainScaffold(
      profile: profile,
      weather: weather,
      result: result,
      onProfileChanged: updateProfile,
      onRefresh: _loadWeather,
      onReset: resetProfile,
    );
  }
}
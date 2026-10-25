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
import 'screens/login_screen.dart';
import 'services/auth_service.dart';

class WeatherSafeApp extends StatelessWidget {
  const WeatherSafeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WeatherSafe',
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF1257A8), // a calm blue
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
  Account? _account;
  bool _accountLoading = true;

  UserProfile? _profile;
  bool _profileLoading = true;

  WeatherSnapshot? _weather;
  bool _weatherLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAccount();
    _loadWeather(); // starts now so it's ready by the time they sign in
  }

  Future<void> _loadAccount() async {
    final account = await AuthService.currentAccount();
    if (!mounted) return;
    setState(() {
      _account = account;
      _accountLoading = false;
    });
    if (account != null) await _loadProfile(account);
  }

  // Each account has its own saved profile.
  Future<void> _loadProfile(Account account) async {
    setState(() => _profileLoading = true);
    StorageService.userId = account.email;
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

  void _signedIn(Account account) {
    setState(() => _account = account);
    _loadProfile(account);
  }

  Future<void> _signOut() async {
    await AuthService.signOut();
    StorageService.userId = null;
    if (!mounted) return;
    setState(() {
      _account = null;
      _profile = null;
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
    const spinner = Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_accountLoading) return spinner;

    final account = _account;
    if (account == null) return LoginScreen(onSignedIn: _signedIn);

    if (_profileLoading) return spinner;
    final profile = _profile;
    if (profile == null) {
      return OnboardingScreen(onComplete: updateProfile);
    }

    // Full-screen spinner only until the first weather arrives. On refresh,
    // keep the app on screen so tab and work-session state survive.
    final weather = _weather;
    if (weather == null) return spinner;
    final result = RiskEngine.assess(weather, profile);

    return MainScaffold(
      profile: profile,
      accountLabel: '${account.name} (${account.email})',
      weather: weather,
      result: result,
      onProfileChanged: updateProfile,
      onRefresh: _loadWeather,
      onReset: resetProfile,
      onSignOut: _signOut,
      refreshing: _weatherLoading,
    );
  }
}

import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../models/weather_snapshot.dart';
import '../services/risk_engine.dart';
import 'home_screen.dart';
import 'help_screen.dart';
import 'checkin_screen.dart';

class MainScaffold extends StatefulWidget {
  const MainScaffold({
    super.key,
    required this.profile,
    required this.weather,
    required this.result,
    required this.onProfileChanged,
    required this.onRefresh,
    required this.onReset,
  });

  final UserProfile profile;
  final WeatherSnapshot weather;
  final RiskResult result;
  final ValueChanged<UserProfile> onProfileChanged;
  final VoidCallback onRefresh;
  final VoidCallback onReset;

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(
        profile: widget.profile,
        weather: widget.weather,
        result: widget.result,
        onProfileChanged: widget.onProfileChanged,
        onRefresh: widget.onRefresh,
        onReset: widget.onReset,
      ),
      CheckinScreen(profile: widget.profile),
      const HelpScreen(),
    ];

    return Scaffold(
      body: screens[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.thermostat), label: 'Today'),
          NavigationDestination(
              icon: Icon(Icons.check_circle_outline), label: 'Check-in'),
          NavigationDestination(icon: Icon(Icons.place), label: 'Nearest Help'),
        ],
      ),
    );
  }
}
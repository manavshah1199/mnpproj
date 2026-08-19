import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../models/weather_snapshot.dart';
import '../services/risk_engine.dart';
import 'home_screen.dart';
import 'help_screen.dart';
import 'checkin_screen.dart';

/// Holds the bottom navigation bar and switches between the main screens.
class MainScaffold extends StatefulWidget {
  const MainScaffold({
    super.key,
    required this.profile,
    required this.weather,
    required this.result,
    required this.onProfileChanged,
    required this.onRefresh,
  });

  final UserProfile profile;
  final WeatherSnapshot weather;
  final RiskResult result;
  final ValueChanged<UserProfile> onProfileChanged;
  final VoidCallback onRefresh;

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _index = 0; // which tab is selected

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(
        profile: widget.profile,
        weather: widget.weather,
        result: widget.result,
        onProfileChanged: widget.onProfileChanged,
        onRefresh: widget.onRefresh,
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
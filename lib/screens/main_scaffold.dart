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
    required this.accountLabel,
    required this.weather,
    required this.result,
    required this.onProfileChanged,
    required this.onRefresh,
    required this.onReset,
    required this.onSignOut,
    this.refreshing = false,
  });

  final UserProfile profile;
  final String accountLabel;
  final WeatherSnapshot weather;
  final RiskResult result;
  final ValueChanged<UserProfile> onProfileChanged;
  final VoidCallback onRefresh;
  final VoidCallback onReset;
  final VoidCallback onSignOut;
  final bool refreshing;

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  static const _helpTab = 2;
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(
        profile: widget.profile,
        accountLabel: widget.accountLabel,
        weather: widget.weather,
        result: widget.result,
        onProfileChanged: widget.onProfileChanged,
        onRefresh: widget.onRefresh,
        onReset: widget.onReset,
        onSignOut: widget.onSignOut,
        onOpenHelp: () => setState(() => _index = _helpTab),
        refreshing: widget.refreshing,
      ),
      CheckinScreen(profile: widget.profile),
      HelpScreen(weather: widget.weather),
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

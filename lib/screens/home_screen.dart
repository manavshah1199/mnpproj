import 'dart:async';
import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../models/weather_snapshot.dart';
import '../services/risk_engine.dart';
import '../services/location_service.dart';
import '../services/weather_service.dart';
import '../services/weather_sim.dart';
import 'settings_screen.dart';

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

class HomeScreen extends StatefulWidget {
  final UserProfile profile;
  const HomeScreen({super.key, required this.profile});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  WeatherSnapshot? _weather;
  bool _loading = true;

  // --- Outdoor-worker session state ---
  DateTime? _sessionStart; // null = not working right now
  Timer? _ticker;          // rebuilds the screen so the countdown updates

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _ticker?.cancel(); // stop the timer when the screen closes
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final loc = await LocationService.getLocation();
    final weather =
        WeatherSim.apply(await WeatherService.fetchWeather(loc.lat, loc.lon));
    if (!mounted) return;
    setState(() {
      _weather = weather;
      _loading = false;
    });
  }

  // How many minutes since the session started.
  int get _sessionMinutes {
    if (_sessionStart == null) return 0;
    return DateTime.now().difference(_sessionStart!).inMinutes;
  }

  void _startSession() {
    setState(() => _sessionStart = DateTime.now());
    // Rebuild every 30s so "next break in X min" stays current.
    _ticker = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  void _endSession() {
    _ticker?.cancel();
    _ticker = null;
    setState(() => _sessionStart = null);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Today\'s Risk'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => SettingsScreen(profile: widget.profile),
                ),
              );
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _buildResult(),
    );
  }

  Widget _buildResult() {
    final weather = _weather!;
    final result = RiskEngine.assess(weather, widget.profile);
    final isWorker = widget.profile.mode == Mode.outdoorWorker;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Colored risk banner
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

        if (weather.isSample)
          const Padding(
            padding: EdgeInsets.only(top: 12),
            child: Text(
              'Showing sample data — live weather was unavailable.',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          ),

        if (weather.isSimulated)
          const Padding(
            padding: EdgeInsets.only(top: 12),
            child: Text(
              'Demo mode: showing simulated weather.',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          ),

        // Outdoor-worker session card (only for that mode)
        if (isWorker) ...[
          const SizedBox(height: 16),
          _workSessionCard(result),
        ],

        const SizedBox(height: 20),
        const Text('Why',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        for (final reason in result.reasons) Text('• $reason'),
        const SizedBox(height: 20),
        const Text('What to do',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        for (final action in result.actions) Text('• $action'),
      ],
    );
  }

  Widget _workSessionCard(RiskResult result) {
    final tracking = _sessionStart != null;
    final work = RiskEngine.workRest(result.feelsLike, _sessionMinutes);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Work session',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (!tracking)
              FilledButton(
                onPressed: _startSession,
                child: const Text('Start work session'),
              )
            else ...[
              Text('Outside for ${_sessionMinutes} min.'),
              const SizedBox(height: 8),
              if (work.applies)
                (work.breakDue
                    ? Text(
                        'Take a break now. ${work.note}',
                        style: const TextStyle(
                            color: Colors.red, fontWeight: FontWeight.bold),
                      )
                    : Text(
                        '${work.note}\nNext break in ${work.minutesUntilBreak} min.'))
              else
                const Text(
                    'Heat index is below the OSHA break threshold — no forced breaks yet.'),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: _endSession,
                child: const Text('End session'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
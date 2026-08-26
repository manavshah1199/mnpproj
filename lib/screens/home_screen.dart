import 'dart:async';
import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../models/weather_snapshot.dart';
import '../services/risk_engine.dart';
import 'settings_screen.dart';

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
  final WeatherSnapshot weather;
  final RiskResult result;
  final ValueChanged<UserProfile> onProfileChanged;
  final VoidCallback onRefresh;
  final VoidCallback onReset;

  const HomeScreen({
    super.key,
    required this.profile,
    required this.weather,
    required this.result,
    required this.onProfileChanged,
    required this.onRefresh,
    required this.onReset,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DateTime? _sessionStart;
  Timer? _ticker;

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  int get _sessionMinutes {
    if (_sessionStart == null) return 0;
    return DateTime.now().difference(_sessionStart!).inMinutes;
  }

  void _startSession() {
    setState(() => _sessionStart = DateTime.now());
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
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: widget.onRefresh,
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => SettingsScreen(
                    profile: widget.profile,
                    onProfileChanged: widget.onProfileChanged,
                    onReset: widget.onReset,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: _buildResult(),
    );
  }

  Widget _buildResult() {
    final weather = widget.weather;
    final result = widget.result;
    final isWorker = widget.profile.mode == Mode.outdoorWorker;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
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
              Text('Outside for $_sessionMinutes min.'),
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
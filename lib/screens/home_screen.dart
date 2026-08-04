import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../models/weather_snapshot.dart';
import '../services/risk_engine.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.profile,
    required this.weather,
    required this.result,
    required this.onProfileChanged,
  });

  final UserProfile profile;
  final WeatherSnapshot weather;
  final RiskResult result;
  final ValueChanged<UserProfile> onProfileChanged;

  Color _colorForLevel(RiskLevel level) {
    switch (level) {
      case RiskLevel.safe:
        return Colors.green;
      case RiskLevel.caution:
        return Colors.orange;
      case RiskLevel.danger:
        return Colors.red;
    }
  }

  String _labelForLevel(RiskLevel level) {
    switch (level) {
      case RiskLevel.safe:
        return 'SAFE';
      case RiskLevel.caution:
        return 'CAUTION';
      case RiskLevel.danger:
        return 'DANGER';
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _colorForLevel(result.level);

    return Scaffold(
      appBar: AppBar(
        title: const Text('WeatherGuard'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (weather.isSample)
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Text(
                'Showing sample data — live NWS data not connected yet.',
                style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
              ),
            ),
          Card(
            color: color.withValues(alpha: 0.15),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _labelForLevel(result.level),
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${weather.locationName} · feels like ${result.feelsLike?.round() ?? '--'}°F',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Why', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          ...result.reasons.map(
            (r) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('•  '),
                  Expanded(child: Text(r)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('What to do', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          ...result.actions.map(
            (a) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.check_circle_outline, size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: Text(a)),
                ],
              ),
            ),
          ),
          if (profile.mode == Mode.outdoorWorker) ...[
            const SizedBox(height: 16),
            _WorkRestCard(feelsLike: result.feelsLike),
          ],
        ],
      ),
    );
  }
}

class _WorkRestCard extends StatelessWidget {
  const _WorkRestCard({required this.feelsLike});

  final double? feelsLike;

  @override
  Widget build(BuildContext context) {
    // TODO: track real session minutes instead of hardcoding 20.
    final workRest = RiskEngine.workRest(feelsLike, 20);
    if (!workRest.applies) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Work/Rest Guidance', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(workRest.note),
            const SizedBox(height: 8),
            Text(
              workRest.breakDue
                  ? 'Break is due now.'
                  : 'Next break in ${workRest.minutesUntilBreak} min.',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: workRest.breakDue ? Colors.red : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
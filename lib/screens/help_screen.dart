import 'package:flutter/material.dart';
import '../models/weather_snapshot.dart';
import '../services/help_service.dart';
import '../services/launcher.dart';

/// Nearby help, ordered by what today's weather calls for.
class HelpScreen extends StatefulWidget {
  final WeatherSnapshot weather;
  const HelpScreen({super.key, required this.weather});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  // Default: Edison, NJ — same fallback as LocationService.
  static const _fallbackLat = 40.5187;
  static const _fallbackLon = -74.4121;

  List<HelpPlace>? _places;
  bool _loading = true;

  double get _lat => widget.weather.lat ?? _fallbackLat;
  double get _lon => widget.weather.lon ?? _fallbackLon;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(HelpScreen old) {
    super.didUpdateWidget(old);
    if (old.weather.lat != widget.weather.lat ||
        old.weather.lon != widget.weather.lon) {
      _load();
    }
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final places = await HelpService.loadAll(_lat, _lon);
    // Nearest first.
    places.sort((a, b) => HelpService.distanceTo(a, _lat, _lon)
        .compareTo(HelpService.distanceTo(b, _lat, _lon)));
    if (!mounted) return;
    setState(() {
      _places = places;
      _loading = false;
    });
  }

  Future<void> _open(Future<bool> launch) async {
    final ok = await launch;
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No app on this phone can open that.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final hazards = widget.weather.hazards;
    return Scaffold(
      appBar: AppBar(title: const Text('Nearest Help')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  _emergencyCard(),
                  const SizedBox(height: 12),
                  _hazardSummary(hazards),
                  for (final c in HelpService.categoriesFor(hazards))
                    _categorySection(c, hazards),
                ],
              ),
            ),
    );
  }

  Widget _emergencyCard() {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: scheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('In danger right now? Call 911.',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: scheme.onErrorContainer)),
            Text(
              'For shelters, food, and utility help, call 211 — free and '
              'available 24/7.',
              style: TextStyle(color: scheme.onErrorContainer),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                FilledButton.icon(
                  style: FilledButton.styleFrom(backgroundColor: scheme.error),
                  onPressed: () => _open(Launcher.call('911')),
                  icon: const Icon(Icons.call),
                  label: const Text('911'),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () => _open(Launcher.call('211')),
                  icon: const Icon(Icons.support_agent),
                  label: const Text('211'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _hazardSummary(Set<Hazard> hazards) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: hazards.isEmpty
          ? const Text('Calm weather today — here\'s everyday help near you.')
          : Wrap(
              spacing: 6,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Text('Help for today\'s weather:'),
                for (final h in hazards) Chip(label: Text(h.label)),
              ],
            ),
    );
  }

  Widget _categorySection(HelpCategory c, Set<Hazard> hazards) {
    final reason = HelpService.reasonFor(c, hazards);
    final nearby =
        _places!.where((p) => p.category == c).take(3).toList();

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(c.icon, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(c.label,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          if (reason != null)
            Padding(
              padding: const EdgeInsets.only(top: 2, left: 32),
              child: Text(reason,
                  style: const TextStyle(fontStyle: FontStyle.italic)),
            ),
          if (nearby.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 4, left: 32),
              child: Text('None found nearby in our list.'),
            ),
          for (final p in nearby) _placeCard(p),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => _open(Launcher.searchNearby(c.mapsQuery)),
              icon: const Icon(Icons.search),
              label: const Text('Find more near me in Maps'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeCard(HelpPlace p) {
    final miles = HelpService.distanceTo(p, _lat, _lon).toStringAsFixed(1);
    final details = [
      if (p.note.isNotEmpty) p.note,
      [if (p.address.isNotEmpty) p.address, '$miles mi away'].join(' · '),
    ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(p.name,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
                if (p.isSample)
                  const Chip(
                    label: Text('Sample', style: TextStyle(fontSize: 11)),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
            for (final line in details) Text(line),
            Row(
              children: [
                TextButton.icon(
                  onPressed: () => _open(Launcher.directions(p.lat, p.lon)),
                  icon: const Icon(Icons.directions),
                  label: const Text('Directions'),
                ),
                if (p.phone.isNotEmpty)
                  TextButton.icon(
                    onPressed: () => _open(Launcher.call(p.phone)),
                    icon: const Icon(Icons.call),
                    label: const Text('Call'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

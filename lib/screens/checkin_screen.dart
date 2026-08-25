import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../services/storage_service.dart';
import '../services/location_service.dart';
import '../services/weather_service.dart';
import '../services/weather_sim.dart';
import '../services/risk_engine.dart';

class CheckinScreen extends StatefulWidget {
  final UserProfile profile;
  const CheckinScreen({super.key, required this.profile});

  @override
  State<CheckinScreen> createState() => _CheckinScreenState();
}

class _CheckinScreenState extends State<CheckinScreen> {
  bool _loading = true;
  DateTime? _lastCheckIn;
  RiskResult? _risk;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final last = await StorageService.loadLastCheckIn();
    final loc = await LocationService.getLocation();
    final weather =
        WeatherSim.apply(await WeatherService.fetchWeather(loc.lat, loc.lon));
    final risk = RiskEngine.assess(weather, widget.profile);
    if (!mounted) return;
    setState(() {
      _lastCheckIn = last;
      _risk = risk;
      _loading = false;
    });
  }

  // Did the last check-in happen today?
  bool get _checkedInToday {
    final last = _lastCheckIn;
    if (last == null) return false;
    final now = DateTime.now();
    return last.year == now.year &&
        last.month == now.month &&
        last.day == now.day;
  }

  Future<void> _checkIn() async {
    await StorageService.recordCheckIn();
    final last = await StorageService.loadLastCheckIn();
    if (!mounted) return;
    setState(() => _lastCheckIn = last);
  }

  // Shows a popup with the exact message that WOULD be texted. Nothing is sent.
  void _previewAlert() {
    final p = widget.profile;
    const message =
        'WeatherSafe alert: someone who listed you as their trusted contact '
        "hasn't checked in during a dangerous weather day. Please check on "
        'them. Automated message — do not reply.';

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Simulated alert'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'To: ${p.contactName.isEmpty ? "your contact" : p.contactName}'
              '${p.contactPhone.isEmpty ? "" : " (${p.contactPhone})"}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(message),
            const SizedBox(height: 8),
            const Text(
              'This is a simulation — no real message is sent.',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Check-in')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final risk = _risk!;
    final hasContact = widget.profile.contactName.isNotEmpty ||
        widget.profile.contactPhone.isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('Check-in')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Today: ${risk.level.name.toUpperCase()}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Check-in button OR a "checked in" confirmation
          if (_checkedInToday)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text("✓ You checked in today. Your contact won't be alerted."),
              ),
            )
          else
            FilledButton(
              onPressed: _checkIn,
              child: const Text("I'm safe — check in"),
            ),
          const SizedBox(height: 24),

          const Text('Safety net',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (hasContact)
            Text(
              "On a Danger day, if you don't check in, WeatherSafe will offer to "
              'alert ${widget.profile.contactName}. That is the only message this '
              'app ever sends — no chat, no sharing.',
            )
          else
            const Text(
              "Add a trusted contact in Settings so someone can be alerted if you "
              "don't check in on a dangerous day.",
            ),
          const SizedBox(height: 16),

          // Let them preview the alert (also handy for demos)
          if (hasContact)
            OutlinedButton(
              onPressed: _previewAlert,
              child: const Text("Preview the alert we'd send"),
            ),
        ],
      ),
    );
  }
}
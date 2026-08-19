import 'package:flutter/material.dart';
import '../models/help_center.dart';
import '../services/centers_service.dart';
import '../services/location_service.dart';

class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  List<HelpCenter>? _centers;
  DeviceLocation? _loc;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final loc = await LocationService.getLocation();
    final centers = await CentersService.loadCenters();

    // Sort nearest-first using the distance from the user.
    centers.sort((a, b) {
      final da = CentersService.distanceMiles(loc.lat, loc.lon, a.lat, a.lon);
      final db = CentersService.distanceMiles(loc.lat, loc.lon, b.lat, b.lon);
      return da.compareTo(db);
    });

    if (!mounted) return;
    setState(() {
      _loc = loc;
      _centers = centers;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nearest Help')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(12),
              children: [
                for (final c in _centers!)
                  Card(
                    child: ListTile(
                      title: Text(c.name),
                      subtitle: Text(
                        '${c.address}\n'
                        '${CentersService.distanceMiles(_loc!.lat, _loc!.lon, c.lat, c.lon).toStringAsFixed(1)} mi away',
                      ),
                      isThreeLine: true,
                      trailing: Text(
                        c.isOpenNow ? 'Open' : 'Closed',
                        style: TextStyle(
                          color: c.isOpenNow ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

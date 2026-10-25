import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../config.dart';

/// Street map with a live temperature heatmap from OpenWeatherMap on top.
/// [interactive] = false keeps it from fighting the page's scrolling.
class WeatherMap extends StatelessWidget {
  final double lat;
  final double lon;
  final bool interactive;

  const WeatherMap({
    super.key,
    required this.lat,
    required this.lon,
    this.interactive = false,
  });

  @override
  Widget build(BuildContext context) {
    final here = LatLng(lat, lon);
    return Stack(
      children: [
        FlutterMap(
          options: MapOptions(
            initialCenter: here,
            initialZoom: interactive ? 8 : 7,
            minZoom: 3,
            maxZoom: 12,
            interactionOptions: InteractionOptions(
              flags: interactive
                  ? InteractiveFlag.all & ~InteractiveFlag.rotate
                  : InteractiveFlag.pinchZoom | InteractiveFlag.doubleTapZoom,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.mnpproj',
            ),
            if (openWeatherMapKey.isNotEmpty)
              Opacity(
                opacity: 0.6,
                child: TileLayer(
                  urlTemplate: 'https://tile.openweathermap.org/map/temp_new/'
                      '{z}/{x}/{y}.png?appid=$openWeatherMapKey',
                  userAgentPackageName: 'com.example.mnpproj',
                ),
              ),
            MarkerLayer(markers: [
              Marker(
                point: here,
                width: 36,
                height: 36,
                alignment: Alignment.topCenter,
                child: const Icon(Icons.location_pin,
                    color: Colors.black87, size: 36),
              ),
            ]),
            const SimpleAttributionWidget(
              source: Text('© OpenStreetMap · OpenWeatherMap',
                  style: TextStyle(fontSize: 10)),
            ),
          ],
        ),
        Positioned(
          left: 8,
          top: 8,
          child: openWeatherMapKey.isEmpty
              ? const _Badge(
                  child: Text('Temperature layer off — no API key',
                      style: TextStyle(fontSize: 11)))
              : const _Badge(child: _Legend()),
        ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  final Widget child;
  const _Badge({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: child,
    );
  }
}

/// Cold-to-hot color key for the OpenWeatherMap temperature layer.
class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('Cold', style: TextStyle(fontSize: 11, color: Colors.black)),
        const SizedBox(width: 4),
        Container(
          width: 90,
          height: 8,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            gradient: const LinearGradient(colors: [
              Color(0xFF8257DB), Color(0xFF208CEC), Color(0xFF23DDDD),
              Color(0xFFC2FF28), Color(0xFFFFF028), Color(0xFFFC8014),
              Color(0xFFFC2014),
            ]),
          ),
        ),
        const SizedBox(width: 4),
        const Text('Hot', style: TextStyle(fontSize: 11, color: Colors.black)),
      ],
    );
  }
}

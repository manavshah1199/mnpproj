import 'package:flutter/material.dart';
import '../models/weather_snapshot.dart';

/// Picks an icon from the forecast wording ("Chance Rain Showers" -> rain).
IconData forecastIcon(String text) {
  final t = text.toLowerCase();
  if (t.contains('thunder') || t.contains('storm')) return Icons.thunderstorm;
  if (t.contains('snow') || t.contains('sleet') || t.contains('ice')) {
    return Icons.ac_unit;
  }
  if (t.contains('rain') || t.contains('shower') || t.contains('drizzle')) {
    return Icons.water_drop;
  }
  if (t.contains('fog') || t.contains('haze')) return Icons.foggy;
  if (t.contains('wind')) return Icons.air;
  if (t.contains('cloud') || t.contains('overcast')) return Icons.cloud;
  if (t.contains('sun') || t.contains('clear')) return Icons.wb_sunny;
  return Icons.wb_cloudy;
}

/// One day in the strip: the daytime high plus the following night's low.
class _Day {
  final String name;
  final String shortForecast;
  final int? high;
  final int? low;
  final int? precipChance;
  _Day(this.name, this.shortForecast, this.high, this.low, this.precipChance);
}

/// A side-scrolling row of the week's weather.
class ForecastStrip extends StatelessWidget {
  final List<ForecastPeriod> periods;
  const ForecastStrip({super.key, required this.periods});

  // Pair each day period with the night after it.
  static List<_Day> _days(List<ForecastPeriod> periods) {
    final days = <_Day>[];
    for (var i = 0; i < periods.length; i++) {
      final p = periods[i];
      if (p.isDaytime) {
        final night = i + 1 < periods.length && !periods[i + 1].isDaytime
            ? periods[i + 1]
            : null;
        days.add(_Day(p.name, p.shortForecast, p.tempF, night?.tempF,
            p.precipChance));
        if (night != null) i++;
      } else {
        // Forecast starts in the evening: show tonight on its own.
        days.add(_Day(p.name, p.shortForecast, null, p.tempF, p.precipChance));
      }
    }
    return days;
  }

  @override
  Widget build(BuildContext context) {
    final days = _days(periods);
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: 150,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: days.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final d = days[i];
          return Container(
            width: 96,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  d.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Tooltip(
                  message: d.shortForecast,
                  child: Icon(forecastIcon(d.shortForecast),
                      size: 30, color: scheme.primary),
                ),
                Text(
                  [
                    if (d.high != null) '${d.high}°',
                    if (d.low != null) '${d.low}°',
                  ].join(' / '),
                ),
                Text(
                  d.precipChance == null || d.precipChance == 0
                      ? ''
                      : '${d.precipChance}% rain',
                  style: const TextStyle(fontSize: 11),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

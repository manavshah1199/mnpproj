import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import '../models/weather_snapshot.dart';
import 'centers_service.dart';

/// The kinds of help the Nearest Help screen can list.
enum HelpCategory {
  shelter, hospital, urgentCare, treeService, handyman, plumber, snowRemoval
}

extension HelpCategoryInfo on HelpCategory {
  String get label {
    switch (this) {
      case HelpCategory.shelter:
        return 'Shelters & cooling/warming centers';
      case HelpCategory.hospital:
        return 'Hospitals';
      case HelpCategory.urgentCare:
        return 'Urgent care';
      case HelpCategory.treeService:
        return 'Tree removal';
      case HelpCategory.handyman:
        return 'Handymen & roof repair';
      case HelpCategory.plumber:
        return 'Plumbers & water damage';
      case HelpCategory.snowRemoval:
        return 'Snow removal';
    }
  }

  IconData get icon {
    switch (this) {
      case HelpCategory.shelter:
        return Icons.night_shelter;
      case HelpCategory.hospital:
        return Icons.local_hospital;
      case HelpCategory.urgentCare:
        return Icons.medical_services;
      case HelpCategory.treeService:
        return Icons.park;
      case HelpCategory.handyman:
        return Icons.handyman;
      case HelpCategory.plumber:
        return Icons.plumbing;
      case HelpCategory.snowRemoval:
        return Icons.ac_unit;
    }
  }

  /// What to search for in Google Maps to find more of these near the user.
  String get mapsQuery {
    switch (this) {
      case HelpCategory.shelter:
        return 'emergency shelter';
      case HelpCategory.hospital:
        return 'hospital';
      case HelpCategory.urgentCare:
        return 'urgent care';
      case HelpCategory.treeService:
        return 'tree removal service';
      case HelpCategory.handyman:
        return 'handyman roof repair';
      case HelpCategory.plumber:
        return 'emergency plumber';
      case HelpCategory.snowRemoval:
        return 'snow removal service';
    }
  }
}

/// One place the user can go to or call.
class HelpPlace {
  final String name;
  final HelpCategory category;
  final double lat;
  final double lon;
  final String address;
  final String phone;
  final String note;      // e.g. "Cooling center · open 9–21"
  final bool isSample;    // placeholder listing that should be replaced

  HelpPlace({
    required this.name,
    required this.category,
    required this.lat,
    required this.lon,
    this.address = '',
    this.phone = '',
    this.note = '',
    this.isSample = false,
  });
}

/// Finds help near the user and decides what matters for today's weather.
class HelpService {
  // Cache live results so switching tabs doesn't re-query the map server.
  static List<HelpPlace>? _liveCache;
  static String? _liveCacheKey;

  /// Which help to show first for the current weather, most urgent first.
  /// Every category is always included so nothing is ever unreachable.
  static List<HelpCategory> categoriesFor(Set<Hazard> hazards) {
    const byHazard = {
      Hazard.storm: [HelpCategory.treeService, HelpCategory.handyman,
          HelpCategory.shelter, HelpCategory.hospital],
      Hazard.wind: [HelpCategory.treeService, HelpCategory.handyman,
          HelpCategory.shelter],
      Hazard.flood: [HelpCategory.shelter, HelpCategory.plumber,
          HelpCategory.handyman, HelpCategory.hospital],
      Hazard.snow: [HelpCategory.snowRemoval, HelpCategory.treeService,
          HelpCategory.shelter, HelpCategory.hospital],
      Hazard.heat: [HelpCategory.shelter, HelpCategory.urgentCare,
          HelpCategory.hospital, HelpCategory.handyman],
      Hazard.cold: [HelpCategory.shelter, HelpCategory.plumber,
          HelpCategory.hospital, HelpCategory.handyman],
      Hazard.rain: [HelpCategory.handyman, HelpCategory.plumber,
          HelpCategory.urgentCare],
    };
    final ordered = <HelpCategory>[];
    // Walk hazards from most to least dangerous so the worst one leads.
    for (final h in Hazard.values.where(hazards.contains).toList()
      ..sort((a, b) => _severityRank(a).compareTo(_severityRank(b)))) {
      for (final c in byHazard[h]!) {
        if (!ordered.contains(c)) ordered.add(c);
      }
    }
    for (final c in HelpCategory.values) {
      if (!ordered.contains(c)) ordered.add(c);
    }
    return ordered;
  }

  /// Why this category matters for the current weather (null if it doesn't).
  static String? reasonFor(HelpCategory c, Set<Hazard> hazards) {
    bool has(Hazard h) => hazards.contains(h);
    switch (c) {
      case HelpCategory.treeService:
        if (has(Hazard.storm) || has(Hazard.wind) || has(Hazard.snow)) {
          return 'Wind and heavy snow bring down trees and limbs.';
        }
      case HelpCategory.handyman:
        if (has(Hazard.storm) || has(Hazard.wind) || has(Hazard.rain)) {
          return 'For roof leaks, broken windows, and storm damage.';
        }
        if (has(Hazard.heat)) return 'For broken AC units.';
        if (has(Hazard.cold)) return 'For broken heating.';
      case HelpCategory.plumber:
        if (has(Hazard.cold)) return 'Freezing temperatures can burst pipes.';
        if (has(Hazard.flood) || has(Hazard.rain)) {
          return 'For flooded basements and sump pump failures.';
        }
      case HelpCategory.snowRemoval:
        if (has(Hazard.snow)) return 'Clear driveways and walkways safely.';
      case HelpCategory.shelter:
        if (has(Hazard.heat)) return 'Cool places to wait out the heat.';
        if (has(Hazard.cold)) return 'Warm places if your heat is out.';
        if (has(Hazard.flood) || has(Hazard.storm)) {
          return 'Safe places if you have to leave home.';
        }
      case HelpCategory.urgentCare:
        if (has(Hazard.heat)) return 'For heat exhaustion that isn\'t an emergency.';
      case HelpCategory.hospital:
        break;
    }
    return null;
  }

  static int _severityRank(Hazard h) =>
      [Hazard.flood, Hazard.storm, Hazard.snow, Hazard.heat, Hazard.cold,
          Hazard.wind, Hazard.rain].indexOf(h);

  /// Everything near (lat, lon): bundled centers + curated services + live map data.
  static Future<List<HelpPlace>> loadAll(double lat, double lon) async {
    final results = await Future.wait([
      _loadCenters(),
      _loadCuratedServices(),
      _loadLive(lat, lon),
    ]);
    return results.expand((list) => list).toList();
  }

  static double distanceTo(HelpPlace p, double lat, double lon) =>
      CentersService.distanceMiles(lat, lon, p.lat, p.lon);

  // The cooling/warming centers from Module 6.
  static Future<List<HelpPlace>> _loadCenters() async {
    final centers = await CentersService.loadCenters();
    return [
      for (final c in centers)
        HelpPlace(
          name: c.name,
          category: HelpCategory.shelter,
          lat: c.lat,
          lon: c.lon,
          address: c.address,
          note: '${_centerType(c.type)} · '
              '${c.isOpenNow ? 'Open now' : 'Closed now'} '
              '(${c.openHour}:00–${c.closeHour}:00)',
        ),
    ];
  }

  static String _centerType(String type) {
    switch (type) {
      case 'cooling':
        return 'Cooling center';
      case 'warming':
        return 'Warming center';
      default:
        return 'Cooling & warming center';
    }
  }

  // Tree services, handymen, etc. from assets/services.json (you control this list).
  static Future<List<HelpPlace>> _loadCuratedServices() async {
    final raw = await rootBundle.loadString('assets/services.json');
    final list = jsonDecode(raw) as List;
    return [
      for (final s in list)
        HelpPlace(
          name: s['name'] ?? '',
          category: HelpCategory.values.byName(s['category']),
          lat: (s['lat'] as num).toDouble(),
          lon: (s['lon'] as num).toDouble(),
          address: s['address'] ?? '',
          phone: s['phone'] ?? '',
          note: s['note'] ?? '',
          isSample: s['sample'] == true,
        ),
    ];
  }

  // Hospitals, urgent cares and shelters from OpenStreetMap (free, no key).
  // Returns an empty list if the map server is slow or unreachable.
  static Future<List<HelpPlace>> _loadLive(double lat, double lon) async {
    final key = '${lat.toStringAsFixed(2)},${lon.toStringAsFixed(2)}';
    if (_liveCacheKey == key && _liveCache != null) return _liveCache!;

    const radius = 25000; // meters (~15 miles)
    final around = '(around:$radius,$lat,$lon)';
    final query = '[out:json][timeout:20];('
        'nwr["amenity"="hospital"]$around;'
        'nwr["healthcare"="urgent_care"]$around;'
        'nwr["amenity"="clinic"]["name"~"urgent|walk-in|immediate|express",i]$around;'
        'nwr["social_facility"="shelter"]$around;'
        ');out center tags 150;';
    try {
      final res = await http.post(
        Uri.parse('https://overpass-api.de/api/interpreter'),
        headers: {'User-Agent': 'WeatherSafe/1.0 (student safety app)'},
        body: {'data': query},
      ).timeout(const Duration(seconds: 25));
      if (res.statusCode != 200) return [];

      final places = <HelpPlace>[];
      for (final e in (jsonDecode(res.body)['elements'] as List)) {
        final tags = Map<String, dynamic>.from(e['tags'] ?? {});
        final name = tags['name'];
        // Ways/relations put their coordinates in "center".
        final pLat = (e['lat'] ?? e['center']?['lat']) as num?;
        final pLon = (e['lon'] ?? e['center']?['lon']) as num?;
        if (name == null || pLat == null || pLon == null) continue;

        final category = tags['social_facility'] == 'shelter'
            ? HelpCategory.shelter
            : tags['amenity'] == 'hospital'
                ? HelpCategory.hospital
                : HelpCategory.urgentCare;
        places.add(HelpPlace(
          name: name,
          category: category,
          lat: pLat.toDouble(),
          lon: pLon.toDouble(),
          address: _address(tags),
          phone: tags['phone'] ?? tags['contact:phone'] ?? '',
          note: tags['emergency'] == 'yes' ? 'Emergency room' : '',
        ));
      }
      _liveCache = places;
      _liveCacheKey = key;
      return places;
    } catch (e) {
      return [];
    }
  }

  static String _address(Map<String, dynamic> tags) {
    final street = [tags['addr:housenumber'], tags['addr:street']]
        .whereType<String>()
        .join(' ');
    final city = tags['addr:city'];
    return [if (street.isNotEmpty) street, ?city].join(', ');
  }
}

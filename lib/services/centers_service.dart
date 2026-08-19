import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart' show rootBundle;
import '../models/help_center.dart';

class CentersService {
  /// Load the centers from the bundled JSON asset.
  static Future<List<HelpCenter>> loadCenters() async {
    final raw = await rootBundle.loadString('assets/centers.json');
    final list = jsonDecode(raw) as List;
    return list.map((item) => HelpCenter.fromJson(item)).toList();
  }

  /// Straight-line distance in miles between two lat/lon points (Haversine).
  static double distanceMiles(
      double lat1, double lon1, double lat2, double lon2) {
    const radius = 3958.8; // Earth's radius in miles
    double toRad(double d) => d * pi / 180;
    final dLat = toRad(lat2 - lat1);
    final dLon = toRad(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(toRad(lat1)) * cos(toRad(lat2)) * sin(dLon / 2) * sin(dLon / 2);
    return radius * 2 * atan2(sqrt(a), sqrt(1 - a));
  }
}

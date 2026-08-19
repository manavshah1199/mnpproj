import 'package:geolocator/geolocator.dart';

/// A simple location result: coordinates + whether we fell back to a default.
class DeviceLocation {
  final double lat;
  final double lon;
  final bool isFallback;
  DeviceLocation({required this.lat, required this.lon, this.isFallback = false});
}

/// Gets the device's location, or a Middlesex/Union County fallback if it
/// can't (permission denied, GPS off, etc.). Never throws.
class LocationService {
  // Default: Edison, NJ (central Middlesex County).
  static final _fallback =
      DeviceLocation(lat: 40.5187, lon: -74.4121, isFallback: true);

  static Future<DeviceLocation> getLocation() async {
    try {
      // Is location turned on at all?
      final serviceOn = await Geolocator.isLocationServiceEnabled();
      if (!serviceOn) return _fallback;

      // Check permission, and ask if we haven't yet.
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return _fallback;
      }

      // Got permission — read the actual position.
      final pos = await Geolocator.getCurrentPosition();
      return DeviceLocation(lat: pos.latitude, lon: pos.longitude);
    } catch (e) {
      return _fallback; // anything unexpected -> safe fallback
    }
  }
}

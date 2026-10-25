import 'package:url_launcher/url_launcher.dart';

/// Hands off to other apps: Maps for directions/search, the dialer for calls.
/// Each returns false if no app could open it.
class Launcher {
  /// Turn-by-turn directions from the user's location to (lat, lon).
  static Future<bool> directions(double lat, double lon) => _open(Uri.https(
      'www.google.com', '/maps/dir/', {'api': '1', 'destination': '$lat,$lon'}));

  /// A Maps search near the user, e.g. "tree removal service".
  static Future<bool> searchNearby(String query) => _open(Uri.https(
      'www.google.com', '/maps/search/', {'api': '1', 'query': query}));

  /// Opens the dialer with the number filled in (the user still taps call).
  static Future<bool> call(String phone) => _open(
      Uri(scheme: 'tel', path: phone.replaceAll(RegExp(r'[^0-9+]'), '')));

  static Future<bool> _open(Uri uri) async {
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      return false;
    }
  }
}

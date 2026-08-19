import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';

/// Saves and loads the user's profile on the phone.
class StorageService {
  static const _profileKey = 'weathersafe.profile';

  /// Save the profile as a JSON string.
  static Future<void> saveProfile(UserProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_profileKey, jsonEncode(profile.toJson()));
  }

  /// Load the saved profile, or null if the user hasn't set one up yet.
  static Future<UserProfile?> loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_profileKey);
    if (raw == null) return null;
    return UserProfile.fromJson(jsonDecode(raw));
  }

  static const _checkInKey = 'weathersafe.lastCheckIn';

  /// Record that the user checked in right now.
  static Future<void> recordCheckIn() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_checkInKey, DateTime.now().toIso8601String());
  }

  /// The time of the last check-in, or null if they never have.
  static Future<DateTime?> loadLastCheckIn() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_checkInKey);
    if (raw == null) return null;
    return DateTime.tryParse(raw);
  }


}
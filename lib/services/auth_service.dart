import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A signed-in user.
class Account {
  final String email;
  final String name;
  Account({required this.email, required this.name});
}

/// Thrown with a message that is safe to show the user.
class AuthException implements Exception {
  final String message;
  AuthException(this.message);
}

/// On-device accounts. Accounts live only on this phone — there is no server.
/// Passwords are never stored: only a salted, repeatedly-hashed fingerprint.
class AuthService {
  static const _usersKey = 'weathersafe.users';
  static const _sessionKey = 'weathersafe.session';

  /// The account that is currently signed in, or null.
  static Future<Account?> currentAccount() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString(_sessionKey);
    if (email == null) return null;
    final user = (await _loadUsers(prefs))[email];
    if (user == null) return null;
    return Account(email: email, name: user['name'] ?? '');
  }

  static Future<Account> register({
    required String name,
    required String email,
    required String password,
  }) async {
    email = _normalize(email);
    if (name.trim().isEmpty) throw AuthException('Please enter your name.');
    if (!email.contains('@') || !email.contains('.')) {
      throw AuthException('Please enter a valid email address.');
    }
    if (password.length < 6) {
      throw AuthException('Password must be at least 6 characters.');
    }

    final prefs = await SharedPreferences.getInstance();
    final users = await _loadUsers(prefs);
    if (users.containsKey(email)) {
      throw AuthException('An account with that email already exists. Sign in instead.');
    }

    final salt = _newSalt();
    users[email] = {
      'name': name.trim(),
      'salt': salt,
      'hash': _hash(password, salt),
    };
    await prefs.setString(_usersKey, jsonEncode(users));
    await prefs.setString(_sessionKey, email);
    return Account(email: email, name: name.trim());
  }

  static Future<Account> signIn({
    required String email,
    required String password,
  }) async {
    email = _normalize(email);
    final prefs = await SharedPreferences.getInstance();
    final user = (await _loadUsers(prefs))[email];
    // Same message either way, so the screen doesn't reveal which emails exist.
    if (user == null || _hash(password, user['salt']!) != user['hash']) {
      throw AuthException('Email or password is incorrect.');
    }
    await prefs.setString(_sessionKey, email);
    return Account(email: email, name: user['name'] ?? '');
  }

  static Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
  }

  static String _normalize(String email) => email.trim().toLowerCase();

  static Future<Map<String, Map<String, String>>> _loadUsers(
      SharedPreferences prefs) async {
    final raw = prefs.getString(_usersKey);
    if (raw == null) return {};
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return decoded.map((k, v) => MapEntry(k, Map<String, String>.from(v)));
  }

  static String _newSalt() {
    final rng = Random.secure();
    return base64Encode(List<int>.generate(16, (_) => rng.nextInt(256)));
  }

  // Hash many times so guessing passwords from a copied phone is slow.
  static String _hash(String password, String salt) {
    List<int> bytes = utf8.encode('$salt:$password');
    for (var i = 0; i < 10000; i++) {
      bytes = sha256.convert(bytes).bytes;
    }
    return base64Encode(bytes);
  }
}

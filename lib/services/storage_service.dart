import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Service: thin wrapper around SharedPreferences.
class StorageService {
  StorageService(this._prefs);

  static const String emailKey = 'saved_email';
  static const String nameKey = 'user_name';
  static const String cartKey = 'saved_cart';
  static const String onboardingKey = 'onboarding_done';
  static const String usersKey = 'registered_users';

  final SharedPreferences _prefs;

  String? get savedEmail => _prefs.getString(emailKey);

  /// Name typed on the register screen. Optional: an account that only ever
  /// signed in has no name, and the app falls back to the email prefix.
  String? get savedName => _prefs.getString(nameKey);

  bool get onboardingDone => _prefs.getBool(onboardingKey) ?? false;

  Map<String, int> loadCart() {
    final String? raw = _prefs.getString(cartKey);
    if (raw == null) return <String, int>{};

    final Object? decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) return <String, int>{};

    return decoded.map(
      (String key, Object? value) => MapEntry(key, (value as num).toInt()),
    );
  }

  Future<void> saveEmail(String email) => _prefs.setString(emailKey, email);

  Future<void> saveName(String name) => _prefs.setString(nameKey, name);

  Future<void> saveCart(Map<String, int> cart) =>
      _prefs.setString(cartKey, jsonEncode(cart));

  Future<void> clearSession() async {
    await _prefs.remove(emailKey);
    await _prefs.remove(nameKey);
  }

  Future<void> clearCart() => _prefs.remove(cartKey);

  Future<void> saveOnboardingDone() => _prefs.setBool(onboardingKey, true);

  Future<void> clearOnboardingDone() => _prefs.remove(onboardingKey);

  Map<String, Map<String, String>> _loadUsers() {
    final String? raw = _prefs.getString(usersKey);
    if (raw == null) return <String, Map<String, String>>{};
    final Object? decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) return <String, Map<String, String>>{};
    return decoded.map(
      (String key, Object? value) => MapEntry(
        key,
        (value as Map<String, dynamic>).map(
          (String k, Object? v) => MapEntry(k, v as String),
        ),
      ),
    );
  }

  Future<void> _saveUsers(Map<String, Map<String, String>> users) async {
    final Map<String, Map<String, dynamic>> enc = users.map(
      (String key, Map<String, String> value) => MapEntry(
        key,
        value.map((String k, String v) => MapEntry(k, v as dynamic)),
      ),
    );
    await _prefs.setString(usersKey, jsonEncode(enc));
  }

  /// Returns the stored password for [email], or null if not registered.
  String? passwordOf(String email) {
    final users = _loadUsers();
    return users[email]?['password'];
  }

  /// Returns the stored name for [email], or null if not registered.
  String? nameOf(String email) {
    final users = _loadUsers();
    return users[email]?['name'];
  }

  /// Creates a new account. Returns an error message, or null on success.
  Future<String?> createAccount({
    required String email,
    required String name,
    required String password,
  }) async {
    final users = _loadUsers();
    if (users.containsKey(email)) {
      return 'Email already registered';
    }
    users[email] = {
      'name': name.trim(),
      'email': email.trim(),
      'password': password,
    };
    await _saveUsers(users);
    return null;
  }

  /// Seeds a demo account (student@school.edu / flutter123) when the store is empty.
  Future<void> ensureDemoAccount() async {
    final users = _loadUsers();
    if (users.isEmpty) {
      users['student@school.edu'] = {
        'name': 'Student',
        'email': 'student@school.edu',
        'password': 'flutter123',
      };
      await _saveUsers(users);
    }
  }
}
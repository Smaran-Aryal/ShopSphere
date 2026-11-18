import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _service = AuthService();

  UserModel? user;
  bool loading = true; // true while checking for a saved session

  // Call once at app start
  Future<void> restoreSession() async {
    final username = await _service.currentUser();
    if (username != null) {
      user = await _service.profileOf(username);
    }
    loading = false;
    notifyListeners();
  }

  // Returns an error message, or null on success
  Future<String?> register({
    required String name,
    required String email,
    required String username,
    required String password,
  }) {
    return _service.register(
      name: name,
      email: email,
      username: username,
      password: password,
    );
  }

  Future<String?> login(String username, String password) async {
    final error = await _service.login(username: username, password: password);
    if (error != null) return error;
    user = await _service.profileOf(username);
    notifyListeners();
    return null;
  }

  Future<void> logout() async {
    await _service.logout();
    user = null;
    notifyListeners();
  }
}
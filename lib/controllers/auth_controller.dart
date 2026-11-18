import 'package:flutter/foundation.dart';
import '../models/password_strength.dart';
import '../services/storage_service.dart';

/// Which account page is showing (sign in, register, forgot password).
enum AuthMode { signIn, register, forgotPassword }

/// Owns the session and account rules; the view renders, the controller decides.
class AuthController extends ChangeNotifier {
  AuthController({
    required StorageService storage,
    DateTime Function()? clock,
    Duration requestLatency = const Duration(milliseconds: 650),
  }) : _storage = storage,
       _clock = clock ?? DateTime.now,
       _requestLatency = requestLatency {
    _email = _storage.savedEmail;
    _name = _storage.savedName;
  }

  /// Shortest password we accept (also used by register meter).
  static const int minPasswordLength = PasswordStrength.minimumLength;

  final StorageService _storage;

  /// Injectable clock for deterministic greetings in tests.
  final DateTime Function() _clock;

  /// Simulated network latency so the busy state is visible.
  final Duration _requestLatency;

  String? _email;
  String? _name;
  bool _isBusy = false;
  AuthMode _mode = AuthMode.signIn;
  String? _resetEmail;

  String? get currentUserEmail => _email;

  String? get currentUserName => _name;

  bool get isSignedIn => _email != null;

  /// Which account page is showing.
  AuthMode get mode => _mode;

  /// True on register and forgot password, where a back button makes sense.
  bool get canGoBack => _mode != AuthMode.signIn;

  /// True while a request is in flight, so the button can show a spinner
  /// instead of pretending the tap did nothing.
  bool get isBusy => _isBusy;

  /// Email a reset link was "sent" to, or null before that happened.
  String? get resetEmail => _resetEmail;

  bool get resetSent => _resetEmail != null;

  /// Email fallback: "student@school.edu" -> "student".
  String get displayName {
    final String name = _name?.trim() ?? '';
    if (name.isNotEmpty) return name;

    final String email = _email ?? '';
    final int at = email.indexOf('@');
    final String fallback = at > 0 ? email.substring(0, at) : email;
    return fallback.isEmpty ? 'there' : fallback;
  }

  String get initial {
    final String name = displayName;
    return name.isEmpty ? '?' : name[0].toUpperCase();
  }

  /// Time-based greeting for the header.
  String get greeting {
    final int hour = _clock().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 18) return 'Good afternoon';
    return 'Good evening';
  }

  static String? validateEmail(String? value) {
    final String email = (value ?? '').trim();
    if (email.isEmpty) return 'Email is required';
    if (!email.contains('@') || !email.contains('.')) {
      return 'Enter a valid email';
    }
    return null;
  }

  static String? validatePassword(String? value) {
    if ((value ?? '').isEmpty) return 'Password is required';
    if ((value ?? '').length < minPasswordLength) {
      return 'Use at least $minPasswordLength characters';
    }
    return null;
  }

  static String? validateName(String? value) {
    final String name = (value ?? '').trim();
    if (name.isEmpty) return 'Name is required';
    if (name.length < 2) return 'Use at least 2 characters';
    return null;
  }

  static String? validateConfirmation(
    String? password,
    String? confirmation,
  ) {
    if ((confirmation ?? '').isEmpty) return 'Repeat the password';
    if (password != confirmation) return 'Passwords do not match';
    return null;
  }

  /// Shared password strength rule for the register meter.
  static PasswordStrength strengthOf(String? value) =>
      PasswordStrength.from(value);

  void showSignIn() => _setMode(AuthMode.signIn);

  void showRegister() => _setMode(AuthMode.register);

  void showForgotPassword() => _setMode(AuthMode.forgotPassword);

  void _setMode(AuthMode mode) {
    if (_mode == mode) return;
    _mode = mode;
    _isBusy = false;
    _resetEmail = null;
    notifyListeners();
  }

  /// Attempts to sign in; returns error message or null on success.
  Future<String?> signIn({required String email, required String password}) async {
    _startRequest();
    await Future<void>.delayed(_requestLatency);

    final String trimmedEmail = email.trim();
    final String storedPassword = _storage.passwordOf(trimmedEmail) ?? '';
    if (storedPassword.isEmpty) {
      _endRequest();
      return 'User not found';
    }
    if (storedPassword != password) {
      _endRequest();
      return 'Incorrect password';
    }

    _email = trimmedEmail;
    _name = _storage.nameOf(trimmedEmail);
    await _storage.saveEmail(_email!);
    if (_name != null) {
      await _storage.saveName(_name!);
    }

    _endRequest();
    return null;
  }

  /// Creates account and signs in; returns error message or null on success.
  Future<String?> register({
    required String name,
    required String email,
    required String password,
  }) async {
    _startRequest();
    await Future<void>.delayed(_requestLatency);

    final String? error = await _storage.createAccount(
      name: name,
      email: email,
      password: password,
    );
    if (error != null) {
      _endRequest();
      return error;
    }

    _name = name.trim();
    _email = email.trim();
    await _storage.saveName(_name!);
    await _storage.saveEmail(_email!);

    _endRequest();
    return null;
  }

/// Pretends to send a reset link (no backend).
  Future<void> sendResetLink({required String email}) async {
    _startRequest();
    await Future<void>.delayed(_requestLatency);

    _resetEmail = email.trim();

    _endRequest();
  }

  /// Dismisses the reset confirmation panel.
  void dismissResetConfirmation() {
    if (_resetEmail == null) return;
    _resetEmail = null;
    notifyListeners();
  }

  Future<void> signOut() async {
    _email = null;
    _name = null;
    _resetEmail = null;
    _mode = AuthMode.signIn;
    await _storage.clearSession();
    notifyListeners();
  }

  void _startRequest() {
    _isBusy = true;
    notifyListeners();
  }

  void _endRequest() {
    _isBusy = false;
    notifyListeners();
  }
}

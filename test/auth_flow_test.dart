import 'package:ecommerce/controllers/auth_controller.dart';
import 'package:ecommerce/models/password_strength.dart';
import 'package:ecommerce/services/storage_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers.dart';

void main() {
  group('AuthController rules', () {
    late AuthController auth;

    setUp(() async {
      auth = (await buildControllers()).auth;
    });

    test('starts on sign in and can move between the account pages', () {
      expect(auth.mode, AuthMode.signIn);
      expect(auth.canGoBack, isFalse);

      auth.showRegister();
      expect(auth.mode, AuthMode.register);
      expect(auth.canGoBack, isTrue);

      auth.showForgotPassword();
      expect(auth.mode, AuthMode.forgotPassword);

      auth.showSignIn();
      expect(auth.mode, AuthMode.signIn);
    });

    test('validates the register fields', () {
      expect(AuthController.validateName(null), 'Name is required');
      expect(AuthController.validateName('A'), 'Use at least 2 characters');
      expect(AuthController.validateName('Ada Lovelace'), isNull);

      expect(AuthController.validateConfirmation('flutter123', ''), 'Repeat the password');
      expect(
        AuthController.validateConfirmation('flutter123', 'other123'),
        'Passwords do not match',
      );
      expect(
        AuthController.validateConfirmation('flutter123', 'flutter123'),
        isNull,
      );
    });

    test('grades the password from short to strong', () {
      expect(AuthController.strengthOf(''), PasswordStrength.tooShort);
      expect(AuthController.strengthOf('abc'), PasswordStrength.tooShort);
      expect(AuthController.strengthOf('flutter'), PasswordStrength.weak);
      expect(
        AuthController.strengthOf('flutterrules'),
        PasswordStrength.fair,
      );
      expect(
        AuthController.strengthOf('flutterrulesabc'),
        PasswordStrength.good,
      );
      expect(
        AuthController.strengthOf('Fl4utter!rules2026'),
        PasswordStrength.strong,
      );
    });

    test('register stores the name and signs the account in', () async {
      await auth.register(
        name: '  Ada Lovelace  ',
        email: ' ada@school.edu ',
        password: 'flutter123',
      );

      expect(auth.isSignedIn, isTrue);
      expect(auth.currentUserEmail, 'ada@school.edu');
      expect(auth.currentUserName, 'Ada Lovelace');
      expect(auth.displayName, 'Ada Lovelace');
      expect(auth.initial, 'A');

      final SharedPreferences prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(StorageService.emailKey), 'ada@school.edu');
      expect(prefs.getString(StorageService.nameKey), 'Ada Lovelace');
    });

    test('a signed in account without a name falls back to the email', () async {
      // Register first, then sign in to test the fallback (the demo account has a name)
      await auth.register(
        name: '',
        email: 'noname@school.edu',
        password: 'flutter123',
      );
      await auth.signOut();

      await auth.signIn(email: 'noname@school.edu', password: 'flutter123');

      // Account registered with empty name falls back to email prefix
      expect(auth.displayName, 'noname');
      expect(auth.initial, 'N');
    });

    test('a reset link remembers the address until it is dismissed', () async {
      expect(auth.resetSent, isFalse);

      await auth.sendResetLink(email: ' lost@school.edu ');

      expect(auth.resetSent, isTrue);
      expect(auth.resetEmail, 'lost@school.edu');

      auth.dismissResetConfirmation();
      expect(auth.resetSent, isFalse);

      auth.showForgotPassword();
      await auth.sendResetLink(email: 'lost@school.edu');
      expect(auth.resetSent, isTrue);

      auth.showSignIn();
      expect(auth.resetSent, isFalse, reason: 'leaving the page clears it');
    });

    test('signing out clears the session, the name and the page', () async {
      await auth.register(
        name: 'Ada Lovelace',
        email: 'ada@school.edu',
        password: 'flutter123',
      );
      auth.showRegister();

      await auth.signOut();

      expect(auth.isSignedIn, isFalse);
      expect(auth.currentUserName, isNull);
      expect(auth.mode, AuthMode.signIn);

      final SharedPreferences prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(StorageService.emailKey), isNull);
      expect(prefs.getString(StorageService.nameKey), isNull);
    });

    test('the busy flag is on while a request runs', () async {
      // Need a registered account for signIn to work
      final AuthController slow = AuthController(
        storage: StorageService(await _prefs()),
        requestLatency: const Duration(milliseconds: 40),
      );
      await slow.register(
        name: 'Test User',
        email: 'a@b.com',
        password: 'flutter123',
      );
      await slow.signOut();

      final Future<void> pending = slow.signIn(
        email: 'a@b.com',
        password: 'flutter123',
      );
      expect(slow.isBusy, isTrue);

      await pending;
      expect(slow.isBusy, isFalse);
    });
  });

  group('Account pages', () {
    testWidgets('the login page links to register and forgot password', (
      WidgetTester tester,
    ) async {
      await pumpShop(tester);

      expect(find.text('Welcome to Shop'), findsOneWidget);

      await tester.tap(find.byKey(const Key('register_link')));
      await tester.pumpAndSettle();

      expect(find.text('Create your account'), findsOneWidget);
      expect(find.byKey(const Key('name_field')), findsOneWidget);
      expect(find.byKey(const Key('confirm_field')), findsOneWidget);
      expect(find.byKey(const Key('auth_back_button')), findsOneWidget);

      await tester.tap(find.byKey(const Key('auth_back_button')));
      await tester.pumpAndSettle();
      expect(find.text('Welcome to Shop'), findsOneWidget);

      await tester.tap(find.byKey(const Key('forgot_password_link')));
      await tester.pumpAndSettle();
      expect(find.text('Reset your password'), findsOneWidget);
      expect(find.byKey(const Key('send_reset_button')), findsOneWidget);
    });

    testWidgets('the register form reports every empty field', (
      WidgetTester tester,
    ) async {
      await pumpShop(tester);
      await tester.tap(find.byKey(const Key('register_link')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('create_account_button')));
      await tester.pumpAndSettle();

      expect(find.text('Name is required'), findsOneWidget);
      expect(find.text('Email is required'), findsOneWidget);
      expect(find.text('Password is required'), findsOneWidget);
      expect(find.text('Repeat the password'), findsOneWidget);
      expect(find.byKey(const Key('product_p1')), findsNothing);
    });

    testWidgets('mismatched passwords keep the user on the page', (
      WidgetTester tester,
    ) async {
      await pumpShop(tester);
      await tester.tap(find.byKey(const Key('register_link')));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('name_field')), 'Ada Lovelace');
      await tester.enterText(find.byKey(const Key('email_field')), 'ada@school.edu');
      await tester.enterText(find.byKey(const Key('password_field')), 'flutter123');
      await tester.enterText(find.byKey(const Key('confirm_field')), 'flutter124');
      await tester.tap(find.byKey(const Key('create_account_button')));
      await tester.pumpAndSettle();

      expect(find.text('Passwords do not match'), findsOneWidget);
      expect(find.byKey(const Key('create_account_button')), findsOneWidget);
    });

    testWidgets('the strength meter follows the password', (
      WidgetTester tester,
    ) async {
      await pumpShop(tester);
      await tester.tap(find.byKey(const Key('register_link')));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('password_field')), 'flutter');
      await tester.pumpAndSettle();
      expect(
        find.text('Password strength: Weak'),
        findsOneWidget,
      );

      await tester.enterText(
        find.byKey(const Key('password_field')),
        'Fl4utter!rules2026',
      );
      await tester.pumpAndSettle();
      expect(find.text('Password strength: Strong'), findsOneWidget);
    });

    testWidgets('registering signs the new account straight in', (
      WidgetTester tester,
    ) async {
      final controllers = await pumpShop(tester);
      await tester.tap(find.byKey(const Key('register_link')));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('name_field')), 'Ada Lovelace');
      await tester.enterText(find.byKey(const Key('email_field')), 'ada@school.edu');
      await tester.enterText(find.byKey(const Key('password_field')), 'flutter123');
      await tester.enterText(find.byKey(const Key('confirm_field')), 'flutter123');
      await tester.tap(find.byKey(const Key('create_account_button')));
      await tester.pumpAndSettle();

      expect(controllers.auth.currentUserEmail, 'ada@school.edu');
      expect(find.text('Ada Lovelace'), findsOneWidget);
      expect(find.byKey(const Key('product_p1')), findsOneWidget);
    });

    testWidgets('the privacy note opens and closes', (
      WidgetTester tester,
    ) async {
      await pumpShop(tester);
      await tester.tap(find.byKey(const Key('register_link')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('register_help_button')));
      await tester.pumpAndSettle();
      expect(find.text('Your data stays on this device'), findsOneWidget);

      await tester.tap(find.byKey(const Key('close_privacy_note')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('create_account_button')), findsOneWidget);
    });

    testWidgets('a reset link is confirmed and can be resent', (
      WidgetTester tester,
    ) async {
      final controllers = await pumpShop(tester);
      await tester.tap(find.byKey(const Key('forgot_password_link')));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('email_field')), 'nope');
      await tester.tap(find.byKey(const Key('send_reset_button')));
      await tester.pumpAndSettle();
      expect(find.text('Enter a valid email'), findsOneWidget);

      await tester.enterText(find.byKey(const Key('email_field')), 'ada@school.edu');
      await tester.tap(find.byKey(const Key('send_reset_button')));
      await tester.pumpAndSettle();

      expect(controllers.auth.resetSent, isTrue);
      expect(find.text('Check your inbox'), findsOneWidget);
      expect(find.byKey(const Key('reset_confirmation')), findsOneWidget);
      expect(find.text('Link sent to ada@school.edu'), findsOneWidget);
      expect(find.byKey(const Key('sign_in_link')), findsNothing);

      await tester.tap(find.byKey(const Key('resend_button')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('reset_confirmation')), findsOneWidget);

      await tester.tap(find.byKey(const Key('use_another_email_button')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('send_reset_button')), findsOneWidget);
      expect(controllers.auth.resetSent, isFalse);

      await tester.tap(find.byKey(const Key('sign_in_link')));
      await tester.pumpAndSettle();
      expect(find.text('Welcome to Shop'), findsOneWidget);
    });
  });
}

Future<SharedPreferences> _prefs() async {
  SharedPreferences.setMockInitialValues(<String, Object>{});
  return SharedPreferences.getInstance();
}

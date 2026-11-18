import 'package:ecommerce/controllers/shop_controllers.dart';
import 'package:ecommerce/main.dart';
import 'package:ecommerce/services/product_service.dart';
import 'package:ecommerce/services/storage_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Fixed "now" so the greeting in the app bar never changes between runs.
final DateTime fixedNoon = DateTime(2026, 5, 4, 12);

/// Controllers wired to fake storage and a product service with no latency.
Future<ShopControllers> buildControllers({
  Map<String, Object> initialPrefs = const <String, Object>{},
  bool seedDemoAccount = true,
}) async {
  SharedPreferences.setMockInitialValues(initialPrefs);
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final StorageService storage = StorageService(prefs);
  if (seedDemoAccount) {
    await storage.ensureDemoAccount();
  }

  return ShopControllers.create(
    storage: storage,
    productService: ProductService(latency: Duration.zero),
    clock: () => fixedNoon,
    // No fake network delay: the busy state is covered by its own test.
    authLatency: Duration.zero,
  );
}

/// Mounts the whole app with the given controllers.
///
/// The surface is enlarged so a full phone sized layout is on screen: on the
/// default 800x600 test window the catalog grid starts below the fold.
/// Onboarding is marked as seen by default, so tests start at the login page.
Future<ShopControllers> pumpShop(
  WidgetTester tester, {
  Size size = const Size(1000, 1800),
  bool onboardingSeen = true,
  Duration splash = const Duration(milliseconds: 1100),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final ShopControllers controllers = await buildControllers(
    initialPrefs: onboardingSeen
        ? <String, Object>{StorageService.onboardingKey: true}
        : <String, Object>{},
  );
  await tester.pumpWidget(ShopApp(controllers: controllers));
  await settleBoot(tester, splash: splash);
  return controllers;
}

/// Pumps past the splash screen. The splash uses a timer for its minimum
/// visible time, so it is advanced with an explicit `pump` instead of
/// `pumpAndSettle`.
Future<void> settleBoot(
  WidgetTester tester, {
  Duration splash = const Duration(milliseconds: 1100),
}) async {
  await tester.pump();
  await tester.pump(splash + const Duration(milliseconds: 100));
  await tester.pump(const Duration(milliseconds: 400));
}

/// Signs in through the form, the way a user would.
Future<void> signIn(
  WidgetTester tester, {
  String email = 'student@school.edu',
  String password = 'flutter123',
}) async {
  await tester.enterText(find.byKey(const Key('email_field')), email);
  await tester.enterText(find.byKey(const Key('password_field')), password);
  await tester.tap(find.byKey(const Key('sign_in_button')));
  await tester.pumpAndSettle();
}
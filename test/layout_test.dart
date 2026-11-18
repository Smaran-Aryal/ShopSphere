import 'package:ecommerce/controllers/shop_controllers.dart';
import 'package:ecommerce/main.dart';
import 'package:ecommerce/services/storage_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

/// Phone sized surface: the layout has to survive the narrowest common screen
/// (and any RenderFlex overflow fails the test).
const Size phone = Size(390, 844);

void main() {
  testWidgets('the shop lays out on a small phone', (WidgetTester tester) async {
    final controllers = await pumpShop(tester, size: phone);
    await signIn(tester);

    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('product_p1')), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('product_p1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('product_p1')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Aurora Headphones'), findsWidgets);

    await tester.drag(
      find.byKey(const Key('detail_scroll')),
      const Offset(0, -420),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Why you will like it'), findsOneWidget);

    await tester.tap(find.byKey(const Key('add_to_cart_button')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(controllers.cart.itemCount, 1);

    await tester.tap(find.byKey(const Key('open_cart')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('checkout_button')), findsOneWidget);

    await tester.tap(find.byKey(const Key('checkout_button')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Order confirmed'), findsOneWidget);
  });

  testWidgets('the login screen lays out on a small phone', (
    WidgetTester tester,
  ) async {
    await pumpShop(tester, size: phone);

    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('sign_in_button')), findsOneWidget);
  });

  testWidgets('the account sheet and sort sheet fit on a small phone', (
    WidgetTester tester,
  ) async {
    await pumpShop(tester, size: phone);
    await signIn(tester);

    await tester.tap(find.byKey(const Key('sort_button')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Sort products'), findsOneWidget);
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('logout_button')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('sign_out_item')), findsOneWidget);
  });

  testWidgets('the splash fits on a small phone', (WidgetTester tester) async {
    tester.view.physicalSize = phone;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final ShopControllers controllers = await buildControllers(
      initialPrefs: <String, Object>{StorageService.onboardingKey: true},
    );
    await tester.pumpWidget(ShopApp(controllers: controllers));

    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('splash_screen')), findsOneWidget);
    expect(find.byKey(const Key('splash_caption')), findsOneWidget);

    await settleBoot(tester);

    expect(tester.takeException(), isNull);
    expect(find.text('Welcome to Shop'), findsOneWidget);
  });

  testWidgets('the onboarding slides fit on a small phone', (
    WidgetTester tester,
  ) async {
    await pumpShop(tester, size: phone, onboardingSeen: false);

    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('onboarding_next')), findsOneWidget);
    expect(find.text('Step 1 of 3'), findsOneWidget);

    await tester.tap(find.byKey(const Key('onboarding_next')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Step 2 of 3'), findsOneWidget);

    await tester.tap(find.byKey(const Key('dot_2')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.widgetWithText(FilledButton, 'Get started'), findsOneWidget);

    await tester.tap(find.byKey(const Key('onboarding_next')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Welcome to Shop'), findsOneWidget);
  });

  testWidgets('the register page fits on a small phone', (
    WidgetTester tester,
  ) async {
    await pumpShop(tester, size: phone);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const Key('register_link')));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Create your account'), findsOneWidget);
    expect(find.byKey(const Key('name_field')), findsOneWidget);
    expect(find.byKey(const Key('confirm_field')), findsOneWidget);
    expect(find.byKey(const Key('strength_label')), findsOneWidget);

    await tester.enterText(find.byKey(const Key('name_field')), 'Ada Lovelace');
    await tester.enterText(find.byKey(const Key('email_field')), 'ada@school.edu');
    await tester.enterText(find.byKey(const Key('password_field')), 'flutter123');
    await tester.enterText(find.byKey(const Key('confirm_field')), 'flutter123');
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('create_account_button')), findsOneWidget);
  });

  testWidgets('the forgot password page fits on a small phone', (
    WidgetTester tester,
  ) async {
    await pumpShop(tester, size: phone);

    await tester.tap(find.byKey(const Key('forgot_password_link')));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Reset your password'), findsOneWidget);
    expect(find.byKey(const Key('send_reset_button')), findsOneWidget);

    await tester.enterText(find.byKey(const Key('email_field')), 'ada@school.edu');
    await tester.tap(find.byKey(const Key('send_reset_button')));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('reset_confirmation')), findsOneWidget);
    expect(find.text('Link sent to ada@school.edu'), findsOneWidget);
  });
}

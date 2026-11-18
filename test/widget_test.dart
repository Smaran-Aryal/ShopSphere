import 'package:ecommerce/controllers/shop_controllers.dart';
import 'package:ecommerce/views/widgets/product_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

void main() {
  testWidgets('the login screen comes first and has no back button', (
    WidgetTester tester,
  ) async {
    await pumpShop(tester);

    expect(find.text('Welcome to Shop'), findsOneWidget);
    expect(find.byType(BackButton), findsNothing);
  });

  testWidgets('the form blocks an invalid sign in', (WidgetTester tester) async {
    await pumpShop(tester);

    await tester.enterText(find.byKey(const Key('email_field')), 'not-an-email');
    await tester.enterText(find.byKey(const Key('password_field')), '123');
    await tester.tap(find.byKey(const Key('sign_in_button')));
    await tester.pumpAndSettle();

    expect(find.text('Enter a valid email'), findsOneWidget);
    expect(find.text('Use at least 6 characters'), findsOneWidget);
    expect(find.text('Welcome to Shop'), findsOneWidget);
  });

  testWidgets('signing in shows the catalog with the greeting and the grid', (
    WidgetTester tester,
  ) async {
    await pumpShop(tester);

    await signIn(tester);

    expect(find.text('Good afternoon'), findsOneWidget);
    expect(find.text('Student'), findsOneWidget);
    expect(find.byKey(const Key('product_p1')), findsOneWidget);
    expect(find.byKey(const Key('open_cart')), findsOneWidget);
    expect(find.text('10 products'), findsOneWidget);
  });

  testWidgets('the demo button fills the form', (WidgetTester tester) async {
    await pumpShop(tester);

    await tester.tap(find.byKey(const Key('demo_account_button')));
    await tester.pumpAndSettle();

    final TextFormField email = tester.widget(
      find.byKey(const Key('email_field')),
    );
    final TextFormField password = tester.widget(
      find.byKey(const Key('password_field')),
    );
    expect(email.controller?.text, 'student@school.edu');
    expect(password.controller?.text, 'flutter123');
  });

  testWidgets('search and category chips filter the grid', (
    WidgetTester tester,
  ) async {
    await pumpShop(tester);
    await signIn(tester);

    await tester.enterText(find.byKey(const Key('search_field')), 'keyboard');
    await tester.pumpAndSettle();

    expect(find.text('1 result for "keyboard"'), findsOneWidget);
    expect(find.byKey(const Key('product_p2')), findsOneWidget);
    expect(find.byKey(const Key('product_p1')), findsNothing);

    await tester.tap(find.byKey(const Key('clear_search')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('category_Home')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('product_p5')), findsOneWidget);
    expect(find.byKey(const Key('product_p1')), findsNothing);
    expect(find.byKey(const Key('clear_filters')), findsOneWidget);

    await tester.tap(find.byKey(const Key('clear_filters')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('product_p1')), findsOneWidget);
  });

  testWidgets('a search with no match shows the empty state', (
    WidgetTester tester,
  ) async {
    await pumpShop(tester);
    await signIn(tester);

    await tester.enterText(find.byKey(const Key('search_field')), 'zzzz');
    await tester.pumpAndSettle();

    expect(find.text('No products found'), findsOneWidget);

    await tester.tap(find.byKey(const Key('empty_action')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('product_p1')), findsOneWidget);
  });

  testWidgets('the sort sheet reorders the grid', (WidgetTester tester) async {
    await pumpShop(tester);
    await signIn(tester);

    await tester.tap(find.byKey(const Key('sort_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('sort_nameAtoZ')));
    await tester.pumpAndSettle();

    expect(firstVisibleProductId(tester), 'p1');
  });

  testWidgets('the featured carousel is only shown without filters', (
    WidgetTester tester,
  ) async {
    await pumpShop(tester);
    await signIn(tester);

    expect(find.text('Featured'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('search_field')), 'lamp');
    await tester.pumpAndSettle();

    expect(find.text('Featured'), findsNothing);
  });

  testWidgets('tapping a card opens the detail page with the cart in it', (
    WidgetTester tester,
  ) async {
    await pumpShop(tester);
    await signIn(tester);

    await tester.tap(find.byKey(const Key('add_p1')));
    await tester.pumpAndSettle();
    expect(find.text('1'), findsWidgets);

    await tester.tap(find.byKey(const Key('product_p1')));
    await tester.pumpAndSettle();

    expect(find.text('Aurora Headphones'), findsWidgets);
    expect(find.text('Why you will like it'), findsOneWidget);
    expect(find.textContaining('Add another'), findsOneWidget);

    await tester.tap(find.byKey(const Key('open_cart')));
    await tester.pumpAndSettle();

    expect(find.text('Aurora Headphones'), findsOneWidget);
    expect(find.text(r'$129.99'), findsWidgets);
  });

  testWidgets('a sold out product cannot be added to the cart', (
    WidgetTester tester,
  ) async {
    final ShopControllers controllers = await pumpShop(tester);
    await signIn(tester);

    await tester.enterText(find.byKey(const Key('search_field')), 'camera');
    await tester.pumpAndSettle();

    expect(find.text('Out of stock'), findsWidgets);

    await tester.tap(find.byKey(const Key('add_p8')));
    await tester.pumpAndSettle();

    expect(controllers.cart.isEmpty, isTrue);
  });

  testWidgets('the cart totals, applies a promo code and checks out', (
    WidgetTester tester,
  ) async {
    final ShopControllers controllers = await pumpShop(tester);
    await signIn(tester);

    await tester.tap(find.byKey(const Key('add_p1')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('open_cart')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('cart_total')), findsOneWidget);
    expect(
      find.text('Free delivery unlocked'),
      findsOneWidget,
      reason: r'the $129.99 order is over the threshold',
    );

    await tester.enterText(find.byKey(const Key('promo_field')), 'SAVE10');
    await tester.tap(find.byKey(const Key('apply_promo')));
    await tester.pumpAndSettle();
    expect(controllers.cart.promoCode, 'SAVE10');
    expect(find.text('SAVE10 applied'), findsOneWidget);

    await tester.tap(find.byKey(const Key('remove_promo')));
    await tester.pumpAndSettle();
    expect(controllers.cart.promoCode, isNull);

    await tester.tap(find.byKey(const Key('checkout_button')));
    await tester.pumpAndSettle();

    expect(find.text('Order confirmed'), findsOneWidget);
    expect(find.text('Aurora Headphones'), findsOneWidget);
    expect(controllers.cart.isEmpty, isTrue);

    await tester.tap(find.byKey(const Key('continue_shopping')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('product_p1')), findsOneWidget);
  });

  testWidgets('a rejected promo code is reported', (WidgetTester tester) async {
    await pumpShop(tester);
    await signIn(tester);

    await tester.enterText(find.byKey(const Key('search_field')), 'mouse');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('add_p4')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('search_field')), '');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('open_cart')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('promo_field')), 'NOPE');
    await tester.tap(find.byKey(const Key('apply_promo')));
    await tester.pumpAndSettle();

    expect(
      find.text('That promo code is not valid'),
      findsOneWidget,
    );
  });

  testWidgets('the empty cart explains itself', (WidgetTester tester) async {
    await pumpShop(tester);
    await signIn(tester);

    await tester.tap(find.byKey(const Key('open_cart')));
    await tester.pumpAndSettle();

    expect(find.byType(BackButton), findsOneWidget);
    expect(find.text('Your cart is empty'), findsOneWidget);

    await tester.tap(find.byKey(const Key('empty_action')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('product_p1')), findsOneWidget);
  });

  testWidgets('signing out returns to the login screen', (
    WidgetTester tester,
  ) async {
    await pumpShop(tester);
    await signIn(tester);

    await tester.tap(find.byKey(const Key('logout_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('sign_out_item')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Logout'));
    await tester.pumpAndSettle();

    expect(find.text('Welcome to Shop'), findsOneWidget);
    expect(find.byType(BackButton), findsNothing);
  });
}

/// Id of the first card in the grid, read from its `product_<id>` key.
String firstVisibleProductId(WidgetTester tester) {
  final List<ProductCard> cards = tester
      .widgetList<ProductCard>(find.byType(ProductCard))
      .toList();
  if (cards.isEmpty) return '';
  return cards.first.product.id;
}
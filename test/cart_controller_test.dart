import 'package:ecommerce/controllers/auth_controller.dart';
import 'package:ecommerce/controllers/cart_controller.dart';
import 'package:ecommerce/controllers/catalog_controller.dart';
import 'package:ecommerce/controllers/shop_controllers.dart';
import 'package:ecommerce/models/cart_item.dart';
import 'package:ecommerce/models/order.dart';
import 'package:ecommerce/models/product.dart';
import 'package:ecommerce/services/product_service.dart';
import 'package:ecommerce/services/storage_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers.dart';

void main() {
  group('AuthController', () {
    test('starts signed out and greets by the clock', () async {
      final ShopControllers controllers = await buildControllers();

      expect(controllers.auth.isSignedIn, isFalse);
      expect(controllers.auth.greeting, 'Good afternoon');

      controllers.dispose();
    });

    test('validation rules live in the controller', () {
      expect(AuthController.validateEmail(''), 'Email is required');
      expect(AuthController.validateEmail('nope'), 'Enter a valid email');
      expect(AuthController.validateEmail('a@b.com'), isNull);

      expect(AuthController.validatePassword('12345'), isNotNull);
      expect(AuthController.validatePassword('123456'), isNull);
    });

    test('sign in then sign out round trips through storage', () async {
      final ShopControllers controllers = await buildControllers();

      await controllers.auth.signIn(email: 'student@school.edu', password: 'flutter123');
      expect(controllers.auth.isSignedIn, isTrue);
      expect(controllers.auth.displayName, 'Student');
      expect(controllers.auth.initial, 'S');

      final SharedPreferences prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(StorageService.emailKey), 'student@school.edu');

      await controllers.auth.signOut();
      expect(controllers.auth.isSignedIn, isFalse);
      expect(prefs.getString(StorageService.emailKey), isNull);

      controllers.dispose();
    });

    test('a remembered session is restored on the next launch', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        StorageService.emailKey: 'student@school.edu',
      });
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final StorageService storage = StorageService(prefs);
      await storage.ensureDemoAccount();
      final AuthController auth = AuthController(storage: storage);

      expect(auth.isSignedIn, isTrue);
      expect(auth.currentUserEmail, 'student@school.edu');

      auth.dispose();
    });
  });

  group('CartController', () {
    late ShopControllers controllers;
    late Product headphones;

    setUp(() async {
      controllers = await buildControllers();
      await controllers.catalog.loadProducts();
      headphones = controllers.catalog.productById('p1')!;
    });

    tearDown(() => controllers.dispose());

    test('adds, counts and totals items', () async {
      await controllers.cart.add(headphones);
      await controllers.cart.add(headphones, quantity: 2);

      expect(controllers.cart.itemCount, 3);
      expect(controllers.cart.items.length, 1);
      expect(controllers.cart.subtotal, closeTo(389.97, 0.001));
      expect(controllers.cart.quantityOf(headphones), 3);
    });

    test('never goes past the stock on hand', () async {
      final Product watch = controllers.catalog.productById('p3')!;

      await controllers.cart.add(watch, quantity: 99);

      expect(controllers.cart.quantityOf(watch), watch.stock);
    });

    test('decreasing to zero removes the line and can be undone', () async {
      await controllers.cart.add(headphones, quantity: 2);

      await controllers.cart.removeOne(headphones);
      final CartItem? removed = await controllers.cart.removeLine(headphones);

      expect(controllers.cart.isEmpty, isTrue);
      expect(removed?.quantity, 1);

      await controllers.cart.restore(removed!);
      expect(controllers.cart.quantityOf(headphones), 1);
    });

    test('survives a restart because it is stored as JSON', () async {
      await controllers.cart.add(headphones);

      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final CatalogController catalog = CatalogController(
        service: ProductService(latency: Duration.zero),
      );
      await catalog.loadProducts();
      final CartController restored = CartController(
        storage: StorageService(prefs),
        resolveProduct: catalog.productById,
      );

      expect(restored.quantities['p1'], 1);
      expect(restored.itemCount, 1);
      expect(restored.items.single.product.name, 'Aurora Headphones');

      restored.dispose();
    });

    test('shipping is free above the threshold', () async {
      final Product mouse = controllers.catalog.productById('p4')!;

      await controllers.cart.add(mouse);
      expect(controllers.cart.shipping, CartController.standardShipping);
      expect(controllers.cart.amountToFreeShipping, isNotNull);

      await controllers.cart.add(headphones);
      expect(controllers.cart.hasFreeShipping, isTrue);
      expect(controllers.cart.shipping, 0);
      expect(controllers.cart.freeShippingProgress, 1);
    });

    test('the total adds tax, delivery and subtracts the promo', () async {
      await controllers.cart.add(headphones);

      expect(controllers.cart.applyPromo('save10'), isTrue,
          reason: 'codes are case insensitive');
      expect(controllers.cart.discount, closeTo(12.999, 0.001));
      expect(controllers.cart.tax, closeTo((129.99 - 12.999) * 0.08, 0.001));
      expect(controllers.cart.shipping, 0, reason: 'over the free threshold');
      expect(controllers.cart.total, closeTo(126.35, 0.02));

      controllers.cart.removePromo();
      expect(controllers.cart.discount, 0);
    });

    test('an unknown promo code is rejected', () {
      expect(controllers.cart.applyPromo('FREEBEER'), isFalse);
      expect(controllers.cart.promoCode, isNull);
    });

    test('the shipping promo wipes the delivery fee', () async {
      final Product mouse = controllers.catalog.productById('p4')!;
      await controllers.cart.add(mouse);

      expect(controllers.cart.shipping, greaterThan(0));
      expect(controllers.cart.applyPromo('SHIPFREE'), isTrue);
      expect(controllers.cart.shipping, 0);
    });

    test('checkout produces an order and empties the cart', () async {
      await controllers.cart.add(headphones, quantity: 2);

      final Order order = controllers.cart.placeOrder();

      expect(order.id, startsWith('SO-'));
      expect(order.lines.single.name, 'Aurora Headphones');
      expect(order.lines.single.quantity, 2);
      expect(order.itemCount, 2);
      expect(order.totalLabel, startsWith(r'$'));
      expect(controllers.cart.isEmpty, isTrue);

      final SharedPreferences prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(StorageService.cartKey), isNull);
    });

    test('a sold out product cannot be added', () async {
      final Product soldOut = controllers.catalog.productById('p8')!;

      await controllers.cart.add(soldOut);

      expect(controllers.cart.isEmpty, isTrue);
    });

    test('unknown ids are skipped when the lines are built', () async {
      await controllers.cart.add(headphones);
      await controllers.cart.add(Product(
        id: 'ghost',
        name: 'Ghost',
        category: 'Home',
        price: 10,
        rating: 5,
        iconName: 'lamp',
      ));

      expect(controllers.cart.items.length, 1);
      expect(controllers.cart.itemCount, 1);
    });
  });
}
# Shop — Flutter e‑commerce (MVC)

A small shopping app built with Flutter, structured as **MVC**: models hold the
data, controllers own the logic and the state, views are pure widgets that only
draw and forward user intent. Styling lives in one design system, so light and
dark mode, spacing and shapes are decided in a single place.

Written against **Flutter 3.41.2 / Dart 3.11**.

---

## 1. How to run it

```bash
# 1. install the SDK (if you do not have it yet) — https://docs.flutter.dev/get-started/install
flutter --version            # expect 3.41.x or newer, Dart 3.11+

# 2. get the packages
flutter pub get

# 3. pick a target
flutter devices              # shows every connected device / simulator

# 4. run it
flutter devices              # shows every connected device / simulator
flutter run                  # any connected device or simulator listed above
flutter run -d <device-id>   # e.g. -d "iPhone 16" or -d emulator-5554
flutter run --release        # release build

# 5. quality checks
flutter analyze              # expects: No issues found!
flutter test                 # expects: 76 tests, all green
```

Only the **android** and **ios** targets are generated in this repository. To try
another platform, add it once and it stays:

```bash
flutter create --platforms=macos .    # or web, windows, linux
flutter run -d macos
```

Useful extras:

| Command | What it does |
|---|---|
| `flutter test test/cart_controller_test.dart` | run one test file |
| `flutter test --plain-name "checkout"` | run tests matching a name |
| `flutter clean && flutter pub get` | fix a broken build folder |
| `flutter build apk --release` | Android release build |

**Sign in:** enter an email that has been registered and its password.
The demo account `student@school.edu` / `flutter123` is seeded on first launch.
The *Fill demo account* button types those credentials for you.

**Demo behaviour worth trying**

| Try this | What happens |
|---|---|
| Pull down on the shop page | the catalog reloads |
| Tap the sort icon | five sort orders, remember the choice |
| Add a cheap item (Vertex Mouse) | the cart meter counts up to free delivery |
| Type `SAVE10`, `WELCOME15` or `SHIPFREE` in the promo field | discount / free shipping |
| Swipe a cart line to the left | removes it, with an undo snack bar |
| Add the same product twice | the grid tile shows an "n in cart" pill |
| Search `camera` | a sold out product, its add button is disabled |
| Add an item on the detail page | snack bar with a *View cart* action |
| *Forgot password?* → *Send reset link* | the confirmation panel names the address |
| *Create account* → fill the form | the new account is signed in, greeting shows the name |
| Avatar menu → *Show onboarding* | replays the tour, then returns to the shop |
| Clear the app data and relaunch | splash + onboarding run again from scratch |

---

## 2. What is in the app

**Splash** — branded gradient mark that scales in, a determinate progress ring
and a "Preparing your catalog" caption. It waits for a minimum visible time and
prefetches the products, so the shop page never shows an empty grid.

**Onboarding** — three slides shown once on a fresh install: a swipeable
`PageView`, tappable page dots, *Skip*, *Next* and *Get started*. The flag is
stored, so the next launch goes straight to the login screen. Replay it any time
from the avatar menu → *Show onboarding*.

**Sign in** — gradient brand mark, form validation from the controller,
show/hide password, demo autofill, busy state on the button, and links to the
other two account pages. Credentials are verified against the stored user
records; wrong email or password shows a snack bar error.

**Create account** — name, email, password and a repeat field, with a live
four segment strength meter and a privacy note that explains what is stored
where. Duplicate email is rejected. Registering signs the new account straight
in.

**Forgot password** — one field, then a "check your inbox" panel with a resend
button and a way back to a different address. There is no backend, so the panel
is driven by the controller flag rather than a server response.

**Shop (home)** — greeting header, search field, animated category chips, a
*Featured* carousel, a result summary with a *Clear* action, a pull to refresh,
a responsive product grid and a sorting sheet.

**Product detail** — the tile flies in from the list you tapped, price with
strike through discount, stock line, description, benefit list, sticky bar with
quantity stepper and add to cart.

**Cart** — free delivery meter, swipe to delete with undo, quantity steppers,
promo code, order summary (subtotal, discount, delivery, tax, total) and a
sticky checkout bar.

**Order confirmation** — receipt with the order id, the paid lines, what happens
next, and a *Continue shopping* button.

Artwork is code: every product is a gradient tile painted with the colours of
its category plus the icon from the payload, so the app ships no image assets.

---

## 3. Folder structure

```
lib/
├── main.dart                        entry point, MaterialApp, login ⇄ shop gate
│
├── core/                            cross cutting UI infrastructure
│   └── theme/
│       ├── app_tokens.dart           spacing, radii, motion, brand colours, category gradients
│       └── app_theme.dart           light + dark ThemeData generated from one seed colour
│
├── models/                          MODEL — plain data, no Flutter widgets
│   ├── product.dart                 Product: fromJson / toJson / derived getters (sale, stock, labels)
│   ├── cart_item.dart               CartItem: a product plus a quantity, and its line total
│   ├── order.dart                   Order + OrderLine: the receipt snapshot after checkout
│   ├── onboarding_slide.dart        OnboardingSlide + the copy of the three slides
│   └── password_strength.dart       PasswordStrength: grades a password for the register meter
│
├── controllers/                     CONTROLLER — state + rules + ChangeNotifier
│   ├── boot_controller.dart         start up: minimum splash time + catalog prefetch
│   ├── onboarding_controller.dart   first run: which slide, is the tour finished
│   ├── auth_controller.dart         session + all three account pages: mode, sign in, register, reset,
│   │                                validation rules, password grading, restore, greeting
│   ├── catalog_controller.dart      products: loading, search, categories, sorting, filtering
│   ├── cart_controller.dart         cart: quantities, totals, shipping, tax, promo, checkout
│   ├── shop_controllers.dart        creates the five and wires their dependencies
│   └── shop_scope.dart              InheritedWidget that hands them to the views
│
├── services/                        data sources, the only async / IO boundary
│   ├── product_service.dart         "API" call: async fetch + jsonDecode → List<Product>
│   └── storage_service.dart         SharedPreferences: session, cart, registered users (email → {name, email, password})
│
├── data/
│   └── sample_products.dart         the raw JSON payload that stands in for the API
│
└── views/                           VIEW — widgets only, no business rules
    ├── screens/
    │   ├── splash_screen.dart        brand mark, progress ring, starts the boot sequence
    │   ├── onboarding_screen.dart    PageView + dots + skip/next, ends on the sign in page
    │   ├── login_screen.dart         sign in form, demo autofill, links to the other pages
    │   ├── register_screen.dart      create account form with the password strength meter
    │   ├── forgot_password_screen.dart  request a reset link, then the confirmation panel
    │   ├── home_screen.dart         CustomScrollView: header, search, chips, carousel, grid
    │   ├── product_detail_screen.dart
    │   ├── cart_screen.dart
    │   └── order_success_screen.dart
    └── widgets/
        ├── product_visual.dart      gradient artwork + Hero wrapper
        ├── product_card.dart        grid tile + AddToCartButton (with pop animation)
        ├── featured_card.dart       wide carousel tile
        ├── cart_line_tile.dart      cart row, swipe to delete
        ├── order_summary_card.dart  subtotal / discount / delivery / tax / total
        ├── free_shipping_meter.dart animated progress towards free delivery
        ├── promo_code_field.dart    promo input, or the applied chip
        ├── quantity_stepper.dart    − value +
        ├── cart_button.dart         app bar cart icon with animated count bubble
        ├── account_button.dart      avatar menu + sign out confirmation
        ├── search_field.dart        search input + category chips
        ├── price_label.dart         price, original price, saving
        ├── rating_badge.dart        star + rating pill
        ├── auth_scaffold.dart       frame shared by the three account pages
        ├── brand_mark.dart          gradient app mark + soft background glows
        ├── page_dots.dart           animated page indicator
        ├── section_header.dart      heading with optional trailing action
        ├── empty_state.dart         "nothing here" state with an optional action
        ├── catalog_skeleton.dart    pulsing placeholders while loading
        └── shop_snack.dart          one place for every snack bar

test/
├── helpers.dart                     fake storage, instant service, fixed clock, pump + sign in helpers
├── product_test.dart                model: JSON, defaults, discounts, stock labels
├── catalog_controller_test.dart     loading, search, categories, sorting, notifications
├── cart_controller_test.dart        auth + cart rules: totals, stock caps, persistence, promo, orders
├── widget_test.dart                 14 user journeys: login, search, sort, detail, cart, checkout, sign out
├── auth_flow_test.dart              account pages: rules, register, strength meter, reset confirmation
├── startup_test.dart                boot + onboarding rules, splash, slides, replay from the menu
└── layout_test.dart                 every screen on a 390 x 844 phone, no overflow, no exceptions
```

---

## 4. How MVC fits together

```
views/screens + views/widgets      draw state, forward intent
        │  ShopScope.of(context).catalog / .cart / .auth
        ▼
controllers/                        rules, state, ChangeNotifier
        │  ProductService · StorageService
        ▼
services/  →  data/                jsonDecode · SharedPreferences
        │
        ▼
models/                             Product · CartItem · Order · OnboardingSlide · PasswordStrength
```

The rules that make it MVC:

1. **Models are data only.** `Product` cannot import Flutter widgets, and it has
   no idea a service exists.
2. **Controllers own the state and the rules.** Tax rate, free shipping
   threshold, promo codes, password length, email validation, sorting and
   filtering all live in controllers — never in a widget.
3. **Views read state and forward intent.** A screen may own a
   `TextEditingController` or a `Form` key, but it never writes to
   `SharedPreferences`, never calls `jsonDecode` and never computes a total.
4. **Services are the only async / IO boundary.** Swap `ProductService` for a
   real HTTP client and nothing else in the app changes.
5. **Dependencies point inwards.** `views → controllers → services → models`.
   Nothing below `views` knows a widget exists.

### Why three controllers instead of one big state object

| Controller | Owns | Example rule |
|---|---|---|
| `BootController` | start up | "show the splash for at least 1.1 s, fetch in the meantime" |
| `OnboardingController` | first run | "show the tour once, remember that it was seen" |
| `AuthController` | the session and the three account pages | "a password needs 6 characters", "verify stored password" |
| `CatalogController` | products + filters | "sorted by rating when nothing else is chosen" |
| `CartController` | quantities + money | "free delivery above \$75", "never more than the stock on hand" |

They are created once in `ShopControllers.create`, published through
`ShopScope`, and each screen listens only to what it renders:

```dart
// views/screens/home_screen.dart
final ShopControllers controllers = ShopScope.of(context);

return ListenableBuilder(
  listenable: Listenable.merge(controllers.all),
  builder: (context, child) => ... controllers.cart.itemCount ...,
);
```

`CartController` needs product data to price a line, but it must not know about
`CatalogController`. It gets a lookup function instead — dependency injection
without a framework:

```dart
CartController(
  storage: storage,
  resolveProduct: catalog.productById,   // cart asks, catalog answers
);
```

### The whole navigation is one switch

`main.dart` holds the only page transition logic in the app. It listens to the
boot, onboarding and session controllers and picks the screen:

```dart
switch ((booted, onboarded, signedIn)) {
  (false, _, _)       => SplashScreen(),      // the splash starts the boot sequence
  (true, false, _)    => OnboardingScreen(),  // first run only, ends on sign in
  (true, true, false) => switch (auth.mode) { // no session yet
    AuthMode.signIn        => LoginScreen(),
    AuthMode.register      => RegisterScreen(),
    AuthMode.forgotPassword => ForgotPasswordScreen(),
  },
  (true, true, true)  => HomeScreen(),        // signed in
}
```

Because the decision lives in a controller and not in a `Navigator` call,
signing in, signing out, finishing the tour and moving between the account
pages never push or pop a route.
(Those screens are deliberately **not** `const`: a canonicalised `const` widget
is identical to the previous one, and Flutter then skips the rebuild.)

### Where the design system comes in

`core/theme/app_tokens.dart` holds the spacing scale, the radius scale, the
motion durations and one gradient + icon per category. `core/theme/app_theme.dart`
turns a single seed colour into a light and a dark `ThemeData` (cards, chips,
inputs, buttons, snack bars, sheets, page transitions). Views read
`Theme.of(context)` and the tokens, so the app restyles from two files.

---

## 5. Data and persistence

`data/sample_products.dart` holds 10 products as JSON, including the optional
fields `description`, `originalPrice`, `stock` and `featured`.
`ProductService` decodes them after a short delay — replace the body with

```dart
final response = await http.get(Uri.parse('https://example.com/products'));
return (jsonDecode(response.body) as List)
    .map((item) => Product.fromJson(item))
    .toList();
```

and nothing else changes.

Four things are stored on the device with `SharedPreferences`:

| Key | Value |
|---|---|
| `saved_email` | the signed in address, so the session survives a restart |
| `user_name` | `Ada Lovelace`, typed on the register page, cleared on sign out |
| `saved_cart` | `{"p1": 2, "p5": 1}`, the cart survives a restart |
| `onboarding_done` | `true` once the tour was finished or skipped |
| `registered_users` | `{email: {name, email, password}}` — accounts created via register |

The cart stores ids only. Names and prices are resolved from the catalog at read
time, so the stored payload can never go stale.

Registered accounts are created on the *Create account* page. On first launch a
demo account (`student@school.edu` / `flutter123`) is seeded automatically.

Checkout math (all in `CartController`):

```
discount  = subtotal × promo percent
delivery  = 0 above $75 after discount, otherwise $6.95   (free with SHIPFREE)
tax       = (subtotal − discount) × 8 %
total     = subtotal − discount + delivery + tax
```

---

## 6. Tests

```bash
flutter test                          # 76 tests
flutter test test/widget_test.dart    # only the user journeys
```

| File | Covers |
|---|---|
| `product_test.dart` | JSON parsing, defaults for missing fields, discount and stock getters |
| `catalog_controller_test.dart` | loading, search, categories, all five sorts, listener notifications |
| `cart_controller_test.dart` | auth rules, quantities, stock caps, persistence, free shipping, promos, checkout |
| `widget_test.dart` | login → shop → search → sort → detail → cart → promo → checkout → sign out |
| `auth_flow_test.dart` | account page rules, register validation, strength meter, reset confirmation |
| `startup_test.dart` | boot timing and prefetch, onboarding page rules, splash, slides, dots, skip, replay |
| `layout_test.dart` | splash, onboarding and the shop on a 390 × 844 phone, asserting no overflow |

`test/helpers.dart` mounts the app with fake storage, a zero latency product
service and a fixed clock, so the greeting in the app bar is always
"Good afternoon" and the tests never wait on a timer. `settleBoot(tester)`
pushes past the splash (which is deliberately slow enough to be seen) in a few
pumps instead of one long wait.

---

## 7. Things to try next

- swap `ProductService` for a real API and add a loading/error/retry cycle
- add favourites with a second storage key and a heart on the product card
- remember the chosen sort and the last category
- add a `ThemeMode` switch in the account menu (the themes already exist)
- turn the filter sheet into a modal with price and rating ranges
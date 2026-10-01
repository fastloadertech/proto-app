# Proto

A Flutter customer app for protein and fitness essentials, with a charcoal and electric-lime identity, bundled Inter typography, and native vector product artwork. Day 3 extends the local shopping journey with catalog discovery controls, saved addresses, coupons, and a five-stage order timeline.

## Run

From this directory with Flutter on your PATH:

```sh
flutter pub get
flutter analyze
flutter test
flutter run -d chrome
```

This workspace also includes a local Flutter SDK at `../.tools/flutter`. On Windows without a global Flutter installation:

```powershell
..\.tools\flutter\bin\flutter.bat pub get
..\.tools\flutter\bin\flutter.bat analyze
..\.tools\flutter\bin\flutter.bat test
..\.tools\flutter\bin\flutter.bat run -d chrome
```

For Android, connect a device or start an emulator, then run `flutter run`. Android, iOS, and web platform scaffolds are included. Building iOS requires macOS and Xcode.

## Customer flow

Splash → login → guest or explicit demo sign-in → shop → bag → checkout → confirmation → order status.

Browse six categories and twelve local products. Search by product or category name; filter by category, price band, and product form; sort by price, name, or the catalog's existing popularity data. Product details show availability and support a quantity-aware `Add to bag` or `Buy now` action. Each flavour has its own bag quantity. The bag supports increasing or decreasing quantities, removing an entire variant, reopening product details with that flavour selected, and viewing line totals. The bottom tabs preserve your position between Shop, Categories, Bag, and You.

Checkout validates contact details and a delivery address, lets you save and select Home, Work, or Other addresses, displays the same price breakdown as the bag, and lets you choose a demo payment method. Delivery is ₹35 below a ₹499 subtotal and free from ₹499; an empty bag has no delivery fee. `PROTO10` takes 10% off the subtotal, rounded to rupees and capped at ₹250; `FUEL50` takes ₹50 off a subtotal of at least ₹499. Invalid and expired codes show feedback. A code pauses if a bag change makes it ineligible, and the total cannot become negative. Placing a valid local order captures its items, quantities, flavours, unit prices, delivery fee, discount, address, contact, and payment choice before clearing the bag.

Confirmation shows the order ID, captured items, destination, fee, discount, final amount, status, and sample ETA. Open the order status screen with `Track order`, or continue shopping. Open `Your orders` from You to see the current session's orders, newest first, with date, amount, and status, and reopen any order's status.

Login checks a local ten-digit phone number and explicitly labels demo sign-in. It sends no OTP and does not create an authenticated account. Bag contents, favourites, delivery and contact details, payment choices, and order history are all kept only in memory for the current app session. Restarting or refreshing the app resets them.

## Demo payment and status

`Pay on delivery`, `UPI demo`, and `Card demo` are local selections. No money is collected, payment service or UPI app is contacted, or real delivery is arranged.

On the status screen, `Advance demo status` manually moves an order through `Order Placed` → `Confirmed` → `Preparing` → `Out for Delivery` → `Delivered`. The button is disabled at the final stage. This is a controlled demo timeline, with no live tracking or automatic courier updates. Neighborhoods, delivery ETAs, product prices, and nutritional details are sample content.

## Structure

```text
lib/
  app/                     App composition, routes, and tab shell
  core/
    formatters/            Shared rupee formatting
    state/                 AppController, AppScope, delivery and coupon pricing
    theme/                 Central brand colors and Material theme
    widgets/               Brand, buttons, headings, product artwork/cards,
                           and shared PriceSummary
  features/
    auth/presentation/     Splash and demo login
    home/presentation/     Discovery and category shortcuts
    catalog/
      domain/              Immutable product and category models
      data/                LocalCatalogRepository
      presentation/        Categories, searchable listing, product details
    bag/presentation/      Variant quantities, removal, pricing, checkout entry
    checkout/presentation/ Contact, address, payment selection, order submission
    orders/
      domain/              Order, item, address, contact, payment, and status models
      data/                In-memory LocalOrderRepository
      presentation/        Confirmation, status timeline, and order history
    profile/presentation/  Saved products, orders entry, and demo sign-in
test/                      Session-state and customer-journey tests
```

Screens share a single `AppController` through the SDK's `ChangeNotifier` and `InheritedNotifier` scope. `DeliveryPricing`, `CouponPricing`, `formatPrice`, and `PriceSummary` keep bag, checkout, and order totals consistent. Local repositories supply catalog data and capture order snapshots; they provide boundaries for future data sources.

The only packages are Flutter and the SDK's `flutter_test`. Flutter supplies navigation, state notifications, animation, forms, and painting. There are no third-party packages, backend services, payment integrations, or Loader integration.

The existing Expo app in the parent directory is preserved independently. Inter is bundled under the SIL Open Font License in `assets/fonts/OFL.txt`.

## Verification

Day 3 verification with the local Flutter SDK: `flutter analyze` reports no issues, all 49 tests pass, the Flutter engine preview test passes, and `flutter build web` succeeds. The app was launched in Chrome and the live flow was checked through search, product details, quantity, Buy now, saved address, coupon, order confirmation, tracking, and one mock status advance. The live order-status screen was also checked at a 390 × 844 Chrome viewport. Phone, landscape, and desktop layouts are covered by widget tests and engine previews. Native Android and iOS device runs have not been performed.

Run `flutter analyze` and `flutter test` from this directory for static analysis and the complete test suite. To run the Day 2 state and shopping-flow tests separately:

```sh
flutter test test/shopping_state_test.dart test/shopping_flow_test.dart
```

The tests cover login and guest entry; search and category filtering; price and product-form filters; sorting; favourites and flavour-specific quantities; full variant removal; price, coupon, and delivery-fee boundaries; saved-address and checkout validation; local order creation and bag clearing; immutable order details and unique IDs; confirmation, history, and five-stage status progression; and recoverable empty or unknown-order states. An app-level test exercises search → Buy now → saved address → coupon → order → tracking → history. Layout checks include 320 × 640 and 390 × 844 phone viewports, 640 × 320 landscape, and 1440 × 900 desktop.

For Flutter engine renders used in visual review:

```sh
flutter test tool/render_previews_test.dart
```

PNGs are written to `.artifacts/previews/`. Android and iOS platform builds require their corresponding toolchains; the commands above use the web run target.

## Day 2 file changes

23 source, test, tooling, and documentation files were added or updated. Platform scaffolds, dependencies, Loader, and the parent Expo application were preserved.

```text
lib/app/proto_app.dart
lib/core/formatters/currency.dart                         (new)
lib/core/state/app_controller.dart
lib/core/state/delivery_pricing.dart                      (new)
lib/core/widgets/price_summary.dart                       (new)
lib/core/widgets/product_card.dart
lib/core/widgets/proto_button.dart
lib/features/home/presentation/home_screen.dart
lib/features/catalog/data/local_catalog_repository.dart
lib/features/catalog/presentation/product_listing_screen.dart
lib/features/catalog/presentation/product_detail_screen.dart
lib/features/bag/presentation/bag_screen.dart
lib/features/checkout/presentation/checkout_screen.dart    (new)
lib/features/orders/domain/order.dart                     (new)
lib/features/orders/data/local_order_repository.dart      (new)
lib/features/orders/presentation/order_confirmation_screen.dart (new)
lib/features/orders/presentation/order_status_screen.dart (new)
lib/features/orders/presentation/orders_screen.dart       (new)
lib/features/profile/presentation/profile_screen.dart
test/shopping_state_test.dart                             (new)
test/shopping_flow_test.dart                              (new)
tool/render_previews_test.dart
README.md
```

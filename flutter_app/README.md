# Proto

A Flutter customer app for protein and fitness essentials, with a charcoal and electric-lime identity, bundled Inter typography, and native vector product artwork. Day 7 adds API-ready contracts around the existing local shopping journey. The backend is **not connected**.

## Day 7 API-ready architecture

The screens read the catalog through `AppController.catalog` (`CatalogRepository`) instead of static local data. `LocalCatalogSource` adapts the existing `LocalCatalogRepository`, retaining its static API and all mock products. Order screens still use `AppController` and `OrderRepository`; checkout now awaits `AsyncOrderRepository.createAsync` when available. `LocalOrderRepository` implements both. Existing synchronous repository implementations remain compatible. A later `ApiCatalogRepository` and `ApiOrderRepository` can be injected into `AppController` without editing discovery or checkout widgets. Catalog reads are currently synchronous; a future API adapter will need a cache/loading owner for remote catalog refreshes.

`AuthRepository` provides login, logout, and the current customer session. `LocalAuthRepository` handles explicit demo sign-in in memory and issues **no token**. A future `ApiAuthRepository` can return a real session; `CustomerSession.authorizationHeaders` supplies a Bearer header only for a valid token. Guest browsing remains available. Saved addresses and selected payment method remain in `AppController` memory; the checkout and order DTOs define their future wire shape. No credentials or secrets are included.

`lib/core/api/api_models.dart` contains JSON DTOs for customer, auth session, category, product, address, order item, payment, driver assignment, order, and create-order request. These are wire data only; Flutter artwork and colors stay in the UI/domain. `fromJson` and `toJson` round-trip using Dart's built-in JSON-compatible maps. Monetary wire values are **integer INR paise**; the current local UI continues using rupee amounts until an API adapter performs explicit conversion. Timestamps use ISO 8601 UTC. Order status values planned for the API are `pending`, `confirmed`, `preparing`, `out_for_delivery`, `delivered`, and `cancelled`; payment status values include `not_charged`, `pending`, `paid`, `failed`, and `refunded`. No network call or fake server was added.

Day 7 validation: `flutter analyze` reports no issues; all **86** tests pass; `flutter build web --no-web-resources-cdn` succeeds. Chrome was walked through Home → search → product → bag → checkout → saved address → UPI demo → confirmation → orders → reopened details, including status progression and the mock driver. Home was visually reviewed at desktop and 390 × 844 mobile size. The browser walkthrough used local data only; Android/iOS device builds and live backend integration remain future work.

The proposed authenticated order routes are:

| Action | Route | Request | Response |
| --- | --- | --- | --- |
| Create | `POST /v1/customer/orders` | `CreateOrderRequestDto`: `addressId`, `paymentMethod`, `items` (`productId`, `quantity`, optional `flavor`), optional `promoCode` | `OrderDto` |
| List | `GET /v1/customer/orders` | None | Array of `OrderDto` |
| Detail | `GET /v1/customer/orders/{id}` | None | `OrderDto` |
| Cancel | `POST /v1/customer/orders/{id}/cancel` | None | Updated `OrderDto` |
| Status | `GET /v1/customer/orders/{id}/status` | None | `{orderId, status, estimatedDeliveryAt, driver}` |

The server must recalculate availability, prices, promotions, fees, and totals. The create request deliberately omits client-calculated totals. The order response preserves item names, quantities, unit prices, address, payment state, amounts, and timestamps as a snapshot. Driver assignment can carry `deliveryJobId`, name, vehicle, contact, and ETA; the local status progression still supplies a mock driver and job ID. The intended flow is **Proto customer app → NestJS backend → Loader** for dispatch, with delivery status flowing back through the backend to Proto. Proto does not contact Loader directly. Neither backend nor Loader is changed or connected in Day 7.

The auth contract envisions login (`POST /v1/customer/auth/login`), logout (`POST /v1/customer/auth/logout`), and current session (`GET /v1/customer/auth/me`); the exact OTP/token protocol remains to be agreed with the backend. `ApiFailure` maps network, authentication, not-found, validation, server, and unknown failures to stable categories and messages. `ApiConfig.baseUrl` is a development placeholder (`http://localhost:3000`) overridable with `--dart-define=PROTO_API_BASE_URL=...`; it is not used by the local app and no production URL is hardcoded in screens.

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

Browse six categories and twelve local products. Home opens live product search and category listings. Search by product or category name; combine category, available-only, price-band, and product-form filters; sort by price, name, popularity, or rating. Clear search and filters to restore the catalog. One sample product is temporarily unavailable; its card and details explain this and disable purchase. Product details also link to related items from the same category. Available products support a quantity-aware `Add to bag` or `Buy now` action. Each flavour has its own bag quantity. The bag supports increasing or decreasing quantities, removing an entire variant, reopening product details with that flavour selected, and viewing line totals. The bottom tabs preserve your position between Shop, Categories, Bag, and You.

Checkout validates contact details and a delivery address. You can view and edit saved addresses from You or checkout, keep multiple destinations even with the same Home, Work, or Other label, and select one for delivery. Checkout shows the same price breakdown as the bag and lets you choose a demo payment method. Delivery is ₹35 below a ₹499 subtotal and free from ₹499; an empty bag has no delivery fee. `PROTO10` takes 10% off the subtotal, rounded to rupees and capped at ₹250; `FUEL50` takes ₹50 off a subtotal of at least ₹499. Invalid and expired codes show feedback. A code pauses if a bag change makes it ineligible, and the total cannot become negative. Placing a valid local order captures its items, quantities, flavours, unit prices, delivery fee, discount, address, contact, and payment choice before clearing the bag.

Confirmation shows the order ID, captured items, destination, fee, discount, final amount, status, and sample ETA. Open the order details and status screen with `Track order`, or continue shopping. Open `Your orders` from You to see the current session's orders, newest first, with date, amount, and status. Reopened details include the order's placement date and time.

Login checks a local ten-digit phone number and explicitly labels demo sign-in. It sends no OTP and does not create an authenticated account. Bag contents, favourites, delivery and contact details, payment choices, and order history are all kept only in memory for the current app session. Restarting or refreshing the app resets them.

The You tab shows the current demo contact, orders, saved addresses, and saved products. Settings previews local order-update and product-offer preferences. About Proto describes the demo; the mock Log out action returns to sign-in while retaining the current session's shopping data in memory.

## Demo payment and status

`Pay on delivery`, `UPI demo`, and `Card demo` are local selections. No money is collected, payment service or UPI app is contacted, or real delivery is arranged.

On the status screen, `Advance demo status` manually moves an order through `Pending` → `Confirmed` → `Preparing` → `Out for Delivery` → `Delivered`. Pending and Confirmed orders can instead be cancelled after confirmation; Cancelled and Delivered are terminal. Skipped and backward transitions are rejected. The reusable timeline reads the order's status history, including cancellation. This is a controlled demo timeline, with no live tracking or automatic courier updates. Neighborhoods, delivery ETAs, product prices, and nutritional details are sample content.

## Day 6 order and delivery foundation

Placing an order captures a stable ID and time, a copied product snapshot with ID, name, selected flavour, quantity, unit price and line subtotal, the delivery fee and final total, contact and address, demo payment method and `Not charged` status, and a sample arrival time. Later catalog or saved-address changes cannot alter an existing order. The bag clears only after the order is created successfully.

`AppController` centralizes order creation, lookup, status updates, cancellation, and demo reset. Order screens depend on the controller rather than a mock list. `OrderRepository` defines the store contract; `MockOrderRepository` is the in-memory implementation, while `LocalOrderRepository` remains available to existing callers. The read methods are asynchronous so order history and details can show loading, retryable errors, empty history, or an unknown order. A later `ApiOrderRepository` can replace the mock behind the controller without changing the screens.

When a demo order reaches Out for Delivery, its repository record gains a mock driver assignment with name, vehicle type/details, contact number, and estimated arrival. `Contact driver` only explains the demo behavior; it does not place a call. The envisioned integration is **Proto customer app → NestJS backend → Loader driver app**, with the backend owning real order, payment, driver-assignment, and delivery status data. Day 6 makes no network requests and does not modify Loader or its backend. All mock orders and driver data disappear when the app session resets.

## Structure

```text
lib/
  app/                     App composition, routes, and tab shell
  core/
    formatters/            Shared rupee and order-date formatting
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
      domain/              Order snapshots, lifecycle, and repository contract
      data/                In-memory MockOrderRepository
      presentation/        Confirmation, reusable timeline, and order history
    profile/presentation/  Customer details, saved items, settings, and shortcuts
test/                      Session-state and customer-journey tests
```

Screens share a single `AppController` through the SDK's `ChangeNotifier` and `InheritedNotifier` scope. `DeliveryPricing`, `CouponPricing`, `formatPrice`, and `PriceSummary` keep bag, checkout, and order totals consistent. Local repositories supply catalog data and capture order snapshots; the order repository contract provides a boundary for a future data source.

The only packages are Flutter and the SDK's `flutter_test`. Flutter supplies navigation, state notifications, animation, forms, and painting. There are no third-party packages, backend services, payment integrations, or Loader integration.

The existing Expo app in the parent directory is preserved independently. Inter is bundled under the SIL Open Font License in `assets/fonts/OFL.txt`.

## Verification

Day 6 verification with the local Flutter SDK: `flutter analyze` reports no issues, all 78 tests pass, and `flutter build web --no-web-resources-cdn` succeeds. Chrome was checked through Home → live search → product details → bag → checkout → saved address → demo payment → order placement → confirmation → order details → Profile → order history → reopened details. The bag cleared after placement, and the order retained its exact amount, address, and status. The timeline advanced manually to Out for Delivery, showing the mock driver assignment and ETA. Desktop and 390 × 844 mobile Chrome views showed no visible overflow; widget tests also cover 320 × 640 and 1440 × 900 order details. Native Android and iOS device runs have not been performed.

Run `flutter analyze` and `flutter test` from this directory for static analysis and the complete test suite. To run the Day 2 state and shopping-flow tests separately:

```sh
flutter test test/shopping_state_test.dart test/shopping_flow_test.dart
```

The tests cover login and guest entry; live search and empty results; combined category, availability, price, and product-form filters; sorting; product availability and disabled purchase; related products; favourites and flavour-specific quantities; full variant removal; price, coupon, and delivery-fee boundaries; multiple saved addresses with repeated labels; checkout validation; local order creation and bag clearing; immutable order snapshots despite later catalog/address changes; unique and stable IDs; captured payment method/status and ETA; valid and rejected lifecycle transitions; cancellation; mock driver assignment; confirmation and history; loading, retryable error, empty, and unknown-order states; Profile shortcuts and mock settings/logout. App-level tests exercise search → Buy now → saved address → coupon → order → tracking → history, and guest → listing → details → bag → checkout → address. Layout checks include 320 × 640 and 390 × 844 phone viewports, 640 × 320 landscape, and 1440 × 900 desktop, with a scaled-text navigation check at 320 × 640.

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

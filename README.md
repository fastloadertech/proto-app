# Proto / Day 1

A Flutter customer app for protein and fitness essentials, built with a charcoal and electric-lime identity, bundled Inter typography, and native vector product artwork.

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

Splash → login → guest or explicit demo sign-in → shop. Browse six categories, search and sort the twelve local products, view details and nutrition, choose a flavor, save favorites, and manage bag quantities. The bottom tabs preserve your position while moving between Shop, Categories, Bag, and You.

Login validates a local ten-digit phone number and explicitly labels the demo confirmation. It sends no OTP. The bag summary is a preview and places no orders. Delivery neighborhoods and ETA labels are sample UI content. Bag and favorites live only in the current session.

## Structure

```text
lib/
  app/                     App composition, routes, and tab shell
  core/
    state/                 SDK ChangeNotifier and InheritedNotifier scope
    theme/                 Central brand colors and Material theme
    widgets/               Brand, buttons, headings, product artwork/cards
  features/
    auth/presentation/     Splash and login
    home/presentation/     Discovery and category shortcuts
    catalog/
      domain/              Immutable product and category models
      data/                LocalCatalogRepository
      presentation/        Categories, searchable listing, product detail
    bag/presentation/      Local bag and preview summary
    profile/presentation/  Saved products and demo entry
test/                      Controller and customer-navigation tests
```

Screens consume immutable catalog data and shared session state; the repository is the boundary for a future data source. Flutter provides navigation, state notifications, animation, and painting. There are no third-party runtime packages, backend services, or Loader integration.

The existing Expo app in the parent directory is preserved independently. Inter is bundled under the SIL Open Font License in `assets/fonts/OFL.txt`.

## Verification

Validated with Flutter 3.47.5 / Dart 3.13.4: `flutter analyze` reports zero issues; all 14 controller and customer-navigation tests pass. The app was launched in Chrome. Tests cover 320 × 640 and 390 × 844 phone layouts, 640 × 320 landscape, and 1440 × 900 desktop.

To generate Flutter engine renders for visual review, run `flutter test tool/render_previews_test.dart`. PNGs are written to `.artifacts/previews/`. Android and iOS scaffolds are included; native builds were not run on this Windows web test target.

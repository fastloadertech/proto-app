import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:proto/app/proto_app.dart';
import 'package:proto/core/state/app_controller.dart';
import 'package:proto/core/widgets/product_card.dart';
import 'package:proto/features/auth/presentation/login_screen.dart';
import 'package:proto/features/auth/presentation/splash_screen.dart';
import 'package:proto/features/bag/presentation/bag_screen.dart';
import 'package:proto/features/catalog/data/local_catalog_repository.dart';
import 'package:proto/features/catalog/presentation/categories_screen.dart';
import 'package:proto/features/catalog/presentation/product_detail_screen.dart';
import 'package:proto/features/catalog/presentation/product_listing_screen.dart';

void _setViewport(WidgetTester tester, Size size) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> _startApp(WidgetTester tester) async {
  await tester.pumpWidget(const ProtoApp());
  expect(find.byType(SplashScreen), findsOneWidget);
  await tester.pump(const Duration(milliseconds: 1400));
  await tester.pumpAndSettle();
  expect(find.byType(LoginScreen), findsOneWidget);
}

Future<void> _enterAsGuest(WidgetTester tester) async {
  await _startApp(tester);
  await tester.ensureVisible(find.text('Explore as guest'));
  await tester.tap(find.text('Explore as guest'));
  await tester.pumpAndSettle();
  expect(find.text('Fuel your next level.'), findsOneWidget);
}

Future<void> _openProteinCategory(WidgetTester tester) async {
  await tester.tap(find.text('Categories').last);
  await tester.pumpAndSettle();
  expect(find.byType(CategoriesScreen), findsOneWidget);
  await tester.ensureVisible(find.text('Protein').first);
  await tester.tap(find.text('Protein').first);
  await tester.pumpAndSettle();
  expect(find.byType(ProductListingScreen), findsOneWidget);
}

Future<void> _openFirstProduct(WidgetTester tester) async {
  final card = find.byType(ProductCard).first;
  final product = tester.widget<ProductCard>(card).product;
  final title = find.descendant(of: card, matching: find.text(product.name));
  await tester.ensureVisible(title);
  await tester.tap(title);
  await tester.pumpAndSettle();
  expect(find.byType(ProductDetailScreen), findsOneWidget);
}

Future<void> _goBack(WidgetTester tester) async {
  await tester.ensureVisible(find.byTooltip('Back'));
  await tester.pumpAndSettle();
  await tester.pageBack();
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final loader = FontLoader('Inter')
      ..addFont(rootBundle.load('assets/fonts/Inter.ttf'));
    await loader.load();
  });
  testWidgets('splash, login, and guest entry reach the customer home', (
    tester,
  ) async {
    _setViewport(tester, const Size(390, 844));
    await _enterAsGuest(tester);

    expect(find.text('Shop protein'), findsOneWidget);
    expect(find.text('Shop'), findsOneWidget);
    expect(find.text('Categories'), findsOneWidget);
    expect(find.text('Bag'), findsOneWidget);
    expect(find.text('You'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('phone validation and explicit demo sign-in reach home', (
    tester,
  ) async {
    _setViewport(tester, const Size(390, 844));
    await _startApp(tester);

    await tester.ensureVisible(find.text('Continue'));
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Enter a 10-digit mobile number.'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField), '9876543210');
    await tester.ensureVisible(find.text('Continue'));
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Demo sign-in'), findsOneWidget);
    expect(find.textContaining('No OTP is sent.'), findsOneWidget);
    expect(find.byType(LoginScreen), findsOneWidget);

    await tester.tap(find.text('Enter Proto'));
    await tester.pumpAndSettle();
    expect(find.text('Fuel your next level.'), findsOneWidget);
    expect(find.byType(LoginScreen), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'category products open details and back preserves the category',
    (tester) async {
      _setViewport(tester, const Size(390, 844));
      await _enterAsGuest(tester);
      await _openProteinCategory(tester);

      for (final card in tester.widgetList<ProductCard>(
        find.byType(ProductCard),
      )) {
        expect(card.product.categoryId, 'protein');
      }
      await _openFirstProduct(tester);
      await _goBack(tester);
      expect(find.byType(ProductListingScreen), findsOneWidget);
      expect(find.byType(ProductDetailScreen), findsNothing);

      await _goBack(tester);
      expect(find.byType(CategoriesScreen), findsOneWidget);
      await tester.tap(find.text('Shop').last);
      await tester.pumpAndSettle();
      expect(find.text('Fuel your next level.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('catalog search handles no results and a matching product', (
    tester,
  ) async {
    _setViewport(tester, const Size(390, 844));
    await _enterAsGuest(tester);
    await _openProteinCategory(tester);

    await tester.enterText(find.byType(TextField), 'no-such-proto-product');
    await tester.pumpAndSettle();
    expect(find.text('No fuel found just yet.'), findsOneWidget);
    expect(find.byType(ProductCard), findsNothing);

    final product = LocalCatalogRepository.products.first;
    await tester.enterText(find.byType(TextField), product.name);
    await tester.pumpAndSettle();
    expect(find.byType(ProductCard), findsOneWidget);
    expect(
      tester.widget<ProductCard>(find.byType(ProductCard)).product.id,
      product.id,
    );
    expect(find.text('No fuel found just yet.'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'adding from details updates bag quantities and removing empties it',
    (tester) async {
      _setViewport(tester, const Size(390, 844));
      await _enterAsGuest(tester);
      await _openProteinCategory(tester);
      await _openFirstProduct(tester);

      final product = tester
          .widget<ProductDetailScreen>(find.byType(ProductDetailScreen))
          .product;
      final controller = AppScope.of(
        tester.element(find.byType(ProductDetailScreen)),
      );
      await tester.ensureVisible(find.text('Add to bag'));
      await tester.tap(find.text('Add to bag'));
      await tester.pumpAndSettle();
      expect(controller.quantityFor(product.id), 1);
      expect(find.text('1 in bag'), findsOneWidget);

      await _goBack(tester);
      await _goBack(tester);
      await tester.tap(find.text('Bag').last);
      await tester.pumpAndSettle();
      expect(find.byType(BagScreen), findsOneWidget);
      expect(find.text(product.name), findsOneWidget);
      expect(find.text('1 item'), findsOneWidget);

      await tester.tap(find.byTooltip('Add another ${product.name}'));
      await tester.pumpAndSettle();
      expect(controller.quantityFor(product.id), 2);
      expect(find.text('2 items'), findsOneWidget);

      await tester.tap(find.byTooltip('Remove ${product.name}'));
      await tester.pumpAndSettle();
      expect(controller.quantityFor(product.id), 1);
      await tester.tap(find.byTooltip('Remove ${product.name}'));
      await tester.pumpAndSettle();
      expect(controller.cartCount, 0);
      expect(find.text('Make room for good fuel.'), findsOneWidget);
      expect(find.text(product.name), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('saved products can be reopened from the customer profile', (
    tester,
  ) async {
    _setViewport(tester, const Size(390, 844));
    await _enterAsGuest(tester);
    await _openProteinCategory(tester);
    await _openFirstProduct(tester);

    final product = tester
        .widget<ProductDetailScreen>(find.byType(ProductDetailScreen))
        .product;
    await tester.tap(find.byTooltip('Save product'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Remove from saved'), findsOneWidget);

    await _goBack(tester);
    await _goBack(tester);
    await tester.tap(find.text('You').last);
    await tester.pumpAndSettle();
    expect(find.text('Saved for later'), findsOneWidget);
    expect(find.byType(ProductCard), findsOneWidget);
    expect(
      tester.widget<ProductCard>(find.byType(ProductCard)).product.id,
      product.id,
    );

    await _openFirstProduct(tester);
    expect(
      tester
          .widget<ProductDetailScreen>(find.byType(ProductDetailScreen))
          .product
          .id,
      product.id,
    );
    expect(find.byTooltip('Remove from saved'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'catalog sorting shows protein products from lowest price first',
    (tester) async {
      _setViewport(tester, const Size(390, 844));
      await _enterAsGuest(tester);
      await _openProteinCategory(tester);
      await tester.tap(find.text('Recommended'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Price: low to high'));
      await tester.pumpAndSettle();

      final expected =
          LocalCatalogRepository.products
              .where((product) => product.categoryId == 'protein')
              .toList()
            ..sort((a, b) => a.price.compareTo(b.price));
      final cards = tester
          .widgetList<ProductCard>(find.byType(ProductCard))
          .toList();
      expect(cards.length, greaterThanOrEqualTo(2));
      expect(
        cards.map((card) => card.product.id),
        expected.take(cards.length).map((product) => product.id),
      );
      expect(find.text('Price: low to high'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'landscape auth remains usable through dialogs and demo sign-in',
    (tester) async {
      _setViewport(tester, const Size(640, 320));
      await _startApp(tester);
      expect(tester.takeException(), isNull);

      await tester.ensureVisible(find.text('Demo terms'));
      await tester.tap(find.text('Demo terms'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      await tester.tap(find.text('Got it'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await tester.enterText(find.byType(TextFormField), '9876543210');
      await tester.ensureVisible(find.text('Continue'));
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(find.text('Demo sign-in'), findsOneWidget);
      await tester.ensureVisible(find.text('Enter Proto'));
      await tester.tap(find.text('Enter Proto'));
      await tester.pumpAndSettle();
      expect(find.text('Fuel your next level.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  for (final size in [const Size(320, 640), const Size(1440, 900)]) {
    testWidgets('customer navigation renders without errors at $size', (
      tester,
    ) async {
      _setViewport(tester, size);
      await _enterAsGuest(tester);
      expect(tester.takeException(), isNull);

      await _openProteinCategory(tester);
      expect(tester.takeException(), isNull);
      await _openFirstProduct(tester);
      expect(tester.takeException(), isNull);
    });
  }
}

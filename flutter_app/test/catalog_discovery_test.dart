import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:proto/core/state/app_controller.dart';
import 'package:proto/core/theme/proto_theme.dart';
import 'package:proto/core/widgets/product_card.dart';
import 'package:proto/features/catalog/data/local_catalog_repository.dart';
import 'package:proto/features/catalog/domain/product.dart';
import 'package:proto/features/catalog/presentation/product_detail_screen.dart';
import 'package:proto/features/catalog/presentation/product_listing_screen.dart';

void _viewport(WidgetTester tester, Size size) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
}

Future<void> _showScreen(
  WidgetTester tester,
  AppController app,
  Widget screen,
) async {
  addTearDown(app.dispose);
  await tester.pumpWidget(
    AppScope(
      controller: app,
      child: MaterialApp(
        theme: ProtoTheme.theme,
        home: screen,
        routes: {
          '/checkout': (_) =>
              const Scaffold(body: Center(child: Text('Checkout destination'))),
          '/bag': (_) => const Scaffold(body: Text('Bag destination')),
        },
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await (FontLoader(
      'Inter',
    )..addFont(rootBundle.load('assets/fonts/Inter.ttf'))).load();
  });

  test('search matches product names and category display names', () {
    expect(
      LocalCatalogRepository.search(
        '  WHEY isolate  ',
      ).map((product) => product.id),
      ['whey-isolate'],
    );
    expect(
      LocalCatalogRepository.search(
        'SMART SNACKS',
      ).map((product) => product.id),
      LocalCatalogRepository.byCategory('snacks').map((product) => product.id),
    );
    expect(
      LocalCatalogRepository.search('pre-workout').length,
      LocalCatalogRepository.byCategory('preworkout').length,
    );
    expect(LocalCatalogRepository.search('no-such-product'), isEmpty);
    expect(
      LocalCatalogRepository.search('  ').length,
      LocalCatalogRepository.products.length,
    );
  });

  test('category, inclusive price bounds, and product type combine', () {
    final matches = LocalCatalogRepository.browse(
      categoryId: 'hydration',
      minPrice: 89,
      maxPrice: 500,
      form: ProductForm.bottle,
    );
    expect(matches.map((product) => product.id), ['hydration-water']);
    expect(
      LocalCatalogRepository.browse(categoryId: 'hydration', maxPrice: 88),
      isEmpty,
    );
    expect(
      LocalCatalogRepository.browse(categoryId: 'all').length,
      LocalCatalogRepository.products.length,
    );
  });

  test('sorting uses existing catalog names, prices, and review counts', () {
    final sourceOrder = LocalCatalogRepository.products
        .map((product) => product.id)
        .toList();
    final named = LocalCatalogRepository.browse(sort: CatalogSort.name);
    final low = LocalCatalogRepository.browse(sort: CatalogSort.priceLow);
    final high = LocalCatalogRepository.browse(sort: CatalogSort.priceHigh);
    final popular = LocalCatalogRepository.browse(sort: CatalogSort.popular);

    expect(
      named.map((product) => product.name),
      orderedEquals(named.map((product) => product.name).toList()..sort()),
    );
    expect(low.first.price, 89);
    expect(high.first.price, 2499);
    expect(popular.first.reviewCount, 324);
    expect(
      LocalCatalogRepository.popularProducts.map((product) => product.id),
      popular.take(4).map((product) => product.id),
    );
    expect(
      LocalCatalogRepository.products.map((product) => product.id),
      sourceOrder,
    );
  });

  testWidgets('listing filters price and type, then clears and sorts', (
    tester,
  ) async {
    _viewport(tester, const Size(390, 844));
    await _showScreen(tester, AppController(), const ProductListingScreen());

    await _tap(tester, find.text('Filters'));
    await _tap(tester, find.text('Under ₹500'));
    await _tap(tester, find.text('Bottles'));
    await _tap(tester, find.text('Show products'));
    expect(find.text('Filters (2)'), findsOneWidget);
    expect(find.text('2 essentials'), findsOneWidget);
    expect(
      tester
          .widgetList<ProductCard>(find.byType(ProductCard))
          .map((card) => card.product.id),
      ['omega-3', 'hydration-water'],
    );

    await _tap(tester, find.text('Hydration').last);
    expect(find.text('1 essential'), findsOneWidget);
    expect(
      tester.widget<ProductCard>(find.byType(ProductCard)).product.id,
      'hydration-water',
    );

    await _tap(tester, find.text('Filters (2)'));
    await _tap(tester, find.text('Clear filters'));
    await _tap(tester, find.text('Show products'));
    await _tap(tester, find.text('All products'));
    await _tap(tester, find.text('Recommended'));
    await _tap(tester, find.text('Name: A to Z'));
    final cardNames = tester
        .widgetList<ProductCard>(find.byType(ProductCard))
        .map((card) => card.product.name)
        .toList();
    expect(cardNames, orderedEquals(List<String>.of(cardNames)..sort()));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'detail shows category and mock availability; Buy now uses selection',
    (tester) async {
      _viewport(tester, const Size(390, 844));
      final app = AppController();
      final product = LocalCatalogRepository.getById('whey-isolate')!;
      await _showScreen(tester, app, ProductDetailScreen(product: product));

      expect(find.text('Available to order'), findsOneWidget);
      expect(find.text('Protein'), findsOneWidget);
      await _tap(tester, find.text(product.flavors.last));
      await _tap(tester, find.byTooltip('Increase quantity'));
      expect(app.cartCount, 0);
      await _tap(tester, find.text('Buy now'));
      expect(app.quantityFor(product.id, flavor: product.flavors.last), 2);
      expect(find.text('Checkout destination'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}

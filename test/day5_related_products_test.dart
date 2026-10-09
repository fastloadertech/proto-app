import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:proto/core/state/app_controller.dart';
import 'package:proto/core/theme/proto_theme.dart';
import 'package:proto/features/catalog/data/local_catalog_repository.dart';
import 'package:proto/features/catalog/presentation/product_detail_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await (FontLoader(
      'Inter',
    )..addFont(rootBundle.load('assets/fonts/Inter.ttf'))).load();
  });

  testWidgets('related product opens its own details without changing bag', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    final app = AppController();
    addTearDown(app.dispose);
    final whey = LocalCatalogRepository.getById('whey-isolate')!;
    await tester.pumpWidget(
      AppScope(
        controller: app,
        child: MaterialApp(
          theme: ProtoTheme.theme,
          home: ProductDetailScreen(product: whey),
          routes: {
            '/bag': (_) => const Scaffold(body: Text('Bag')),
            '/checkout': (_) => const Scaffold(body: Text('Checkout')),
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Keep the momentum'));
    await tester.pumpAndSettle();
    expect(find.text('Everyday Whey'), findsOneWidget);
    await tester.tap(find.text('Everyday Whey'));
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<ProductDetailScreen>(find.byType(ProductDetailScreen))
          .product
          .id,
      'everyday-whey',
    );
    expect(app.cartCount, 0);
    expect(tester.takeException(), isNull);
  });
}

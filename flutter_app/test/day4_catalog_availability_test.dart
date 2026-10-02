import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:proto/core/state/app_controller.dart';
import 'package:proto/core/theme/proto_theme.dart';
import 'package:proto/core/widgets/product_card.dart';
import 'package:proto/features/catalog/data/local_catalog_repository.dart';
import 'package:proto/features/catalog/presentation/product_detail_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await (FontLoader(
      'Inter',
    )..addFont(rootBundle.load('assets/fonts/Inter.ttf'))).load();
  });

  final unavailable = LocalCatalogRepository.getById('protein-bites')!;

  test(
    'unavailable mock product remains discoverable by search and category',
    () {
      expect(unavailable.isAvailable, isFalse);
      expect(
        LocalCatalogRepository.search('Peanut Butter Bites'),
        contains(unavailable),
      );
      expect(
        LocalCatalogRepository.byCategory('snacks'),
        contains(unavailable),
      );
      expect(
        LocalCatalogRepository.getById('hydration-water')!.isAvailable,
        isTrue,
      );
    },
  );

  test('unavailable products cannot be added through session state', () {
    final app = AppController();
    addTearDown(app.dispose);
    expect(() => app.add(unavailable), throwsStateError);
    expect(app.cartCount, 0);
    expect(app.subtotal, 0);
  });

  testWidgets('unavailable catalog card opens details but cannot add', (
    tester,
  ) async {
    final app = AppController();
    addTearDown(app.dispose);
    var openedDetails = false;
    await tester.pumpWidget(
      AppScope(
        controller: app,
        child: MaterialApp(
          theme: ProtoTheme.theme,
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 160,
                height: 340,
                child: ProductCard(
                  product: unavailable,
                  onTap: () => openedDetails = true,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('UNAVAILABLE'), findsNWidgets(2));
    expect(
      tester
          .widget<OutlinedButton>(
            find.widgetWithText(OutlinedButton, 'UNAVAILABLE'),
          )
          .onPressed,
      isNull,
    );
    expect(app.cartCount, 0);
    await tester.tap(find.text(unavailable.name));
    expect(openedDetails, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('unavailable detail disables purchase at narrow, scaled layout', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 640);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    final app = AppController();
    addTearDown(app.dispose);
    await tester.pumpWidget(
      AppScope(
        controller: app,
        child: MaterialApp(
          theme: ProtoTheme.theme,
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(320, 640),
              textScaler: TextScaler.linear(1.4),
            ),
            child: ProductDetailScreen(product: unavailable),
          ),
          routes: {
            '/checkout': (_) => const Scaffold(body: Text('Checkout')),
            '/bag': (_) => const Scaffold(body: Text('Bag')),
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Temporarily unavailable'), findsOneWidget);
    expect(find.text('At your door in 12 min'), findsNothing);
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Unavailable'),
          )
          .onPressed,
      isNull,
    );
    expect(
      tester
          .widget<OutlinedButton>(
            find.widgetWithText(OutlinedButton, 'Buy now'),
          )
          .onPressed,
      isNull,
    );
    expect(app.cartCount, 0);
    expect(tester.takeException(), isNull);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:proto/core/state/app_controller.dart';
import 'package:proto/core/theme/proto_theme.dart';
import 'package:proto/core/widgets/price_summary.dart';
import 'package:proto/features/catalog/data/local_catalog_repository.dart';
import 'package:proto/features/checkout/presentation/checkout_screen.dart';
import 'package:proto/features/checkout/presentation/delivery_address_screen.dart';

Future<void> _mountCheckout(
  WidgetTester tester,
  AppController app, {
  Size size = const Size(390, 844),
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(app.dispose);
  await tester.pumpWidget(
    AppScope(
      controller: app,
      child: MaterialApp(
        theme: ProtoTheme.theme,
        home: const CheckoutScreen(),
        routes: {
          '/addresses': (_) => const DeliveryAddressScreen(),
          '/shop': (_) => const Scaffold(body: Text('Shop')),
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
  WidgetController.hitTestWarningShouldBeFatal = true;
  setUpAll(() async {
    await (FontLoader(
      'Inter',
    )..addFont(rootBundle.load('assets/fonts/Inter.ttf'))).load();
  });

  testWidgets(
    'saved address editor validates, selects and returns to checkout',
    (tester) async {
      final app = AppController()..add(LocalCatalogRepository.products.first);
      await _mountCheckout(tester, app, size: const Size(320, 640));

      await _tap(tester, find.text('Choose saved address'));
      expect(find.byType(DeliveryAddressScreen), findsOneWidget);
      expect(find.text('Use Home'), findsOneWidget);
      await _tap(tester, find.text('Add another address'));
      await tester.enterText(
        find.byKey(const ValueKey('saved-street-address')),
        '18, Training Lane',
      );
      await tester.enterText(
        find.byKey(const ValueKey('saved-area')),
        'Koramangala',
      );
      await tester.enterText(
        find.byKey(const ValueKey('saved-city')),
        'Bengaluru',
      );
      await tester.enterText(
        find.byKey(const ValueKey('saved-pin-code')),
        '000000',
      );
      await _tap(tester, find.text('Save and use address'));
      expect(find.text('Enter a valid 6-digit PIN code.'), findsOneWidget);
      expect(find.byType(DeliveryAddressScreen), findsOneWidget);
      expect(app.savedAddresses, hasLength(1));

      await tester.enterText(
        find.byKey(const ValueKey('saved-pin-code')),
        '560034',
      );
      await _tap(tester, find.text('Save and use address'));
      expect(find.byType(CheckoutScreen), findsOneWidget);
      expect(app.savedAddresses, hasLength(2));
      expect(app.deliveryAddress.label, 'Work');
      expect(find.text('Deliver to · Work'), findsOneWidget);
      expect(
        tester
            .widget<TextFormField>(
              find.widgetWithText(TextFormField, 'Street address'),
            )
            .controller!
            .text,
        '18, Training Lane',
      );

      await _tap(tester, find.text('Choose saved address'));
      await _tap(tester, find.text('Use Home'));
      expect(app.deliveryAddress.label, 'Home');
      expect(find.text('Deliver to · Home'), findsOneWidget);
      await _tap(tester, find.text('Choose saved address'));
      await _tap(tester, find.text('Use Work'));
      expect(app.deliveryAddress.label, 'Work');
      await _tap(tester, find.text('Place order'));
      expect(app.orders, hasLength(1));
      expect(app.orders.single.address.label, 'Work');
      expect(app.orders.single.address.line1, '18, Training Lane');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('coupon feedback changes totals and survives order creation', (
    tester,
  ) async {
    final water = LocalCatalogRepository.getById('hydration-water')!;
    final app = AppController()..add(water);
    await _mountCheckout(tester, app);
    final promo = find.widgetWithText(TextField, 'Promo code');

    await tester.enterText(promo, 'EXPIRED');
    await _tap(tester, find.text('Apply code'));
    expect(app.couponDiscount, 0);
    expect(app.couponMessage, isNotNull);
    expect(app.couponMessage!.toLowerCase(), contains('expired'));
    expect(find.text(app.couponMessage!), findsOneWidget);

    await tester.enterText(promo, 'WRONG');
    await _tap(tester, find.text('Apply code'));
    expect(app.couponDiscount, 0);
    expect(app.couponMessage, isNotNull);

    await tester.enterText(promo, 'PROTO10');
    await _tap(tester, find.text('Apply code'));
    expect(app.couponCode, 'PROTO10');
    expect(app.couponDiscount, 9);
    expect(app.total, 115);
    expect(tester.widget<PriceSummary>(find.byType(PriceSummary)).discount, 9);
    expect(find.textContaining('PROTO10 applied'), findsOneWidget);

    await _tap(tester, find.text('Remove code'));
    expect(app.couponCode, isNull);
    expect(app.couponDiscount, 0);
    expect(app.total, 124);

    await tester.enterText(promo, 'FUEL50');
    await _tap(tester, find.text('Apply code'));
    expect(app.couponDiscount, 0);
    expect(app.couponMessage, isNotNull);
    app.add(water, quantity: 5);
    await _tap(tester, find.text('Apply code'));
    expect(app.subtotal, 534);
    expect(app.deliveryFee, 0);
    expect(app.couponDiscount, 50);
    expect(app.total, 484);

    app.remove(water);
    await tester.pumpAndSettle();
    expect(app.subtotal, 445);
    expect(app.couponDiscount, 0);
    expect(find.textContaining('FUEL50 paused'), findsOneWidget);
    expect(find.textContaining('FUEL50 applied'), findsNothing);

    app.add(water);
    await tester.pumpAndSettle();
    expect(app.couponDiscount, 50);
    expect(find.textContaining('FUEL50 applied'), findsOneWidget);

    await _tap(tester, find.text('Place order'));
    expect(app.orders, hasLength(1));
    expect(app.orders.single.total, 484);
    expect(app.orders.single.discount, 50);
    expect(app.cartCount, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('address and checkout stay usable at wide web size', (
    tester,
  ) async {
    final app = AppController()..add(LocalCatalogRepository.products.first);
    await _mountCheckout(tester, app, size: const Size(1440, 900));
    expect(tester.takeException(), isNull);
    await _tap(tester, find.text('Choose saved address'));
    expect(find.text('Where should we meet you?'), findsOneWidget);
    await _tap(tester, find.text('Use Home'));
    expect(find.byType(CheckoutScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

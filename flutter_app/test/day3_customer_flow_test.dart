import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:proto/app/proto_app.dart';
import 'package:proto/core/state/app_controller.dart';
import 'package:proto/core/widgets/product_card.dart';
import 'package:proto/features/catalog/data/local_catalog_repository.dart';
import 'package:proto/features/catalog/presentation/product_detail_screen.dart';
import 'package:proto/features/checkout/presentation/checkout_screen.dart';
import 'package:proto/features/checkout/presentation/delivery_address_screen.dart';
import 'package:proto/features/orders/domain/order.dart';
import 'package:proto/features/orders/presentation/order_confirmation_screen.dart';
import 'package:proto/features/orders/presentation/order_status_screen.dart';
import 'package:proto/features/orders/presentation/orders_screen.dart';

Future<void> _tap(WidgetTester tester, Finder finder) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();
  if (finder.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      finder,
      240,
      scrollable: find.byType(Scrollable).first,
    );
  }
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

  testWidgets('search to Buy now, saved address, coupon, order and history', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const ProtoApp());
    await tester.pump(const Duration(milliseconds: 1400));
    await tester.pumpAndSettle();
    await _tap(tester, find.text('Explore as guest'));
    expect(
      find.textContaining('Orders and delivery are simulated'),
      findsOneWidget,
    );
    await _tap(tester, find.text('Search protein, creatine, snacks…'));
    await tester.enterText(find.byType(TextField), 'hydration');
    await tester.pumpAndSettle();

    final water = LocalCatalogRepository.getById('hydration-water')!;
    final waterCard = find.byWidgetPredicate(
      (widget) => widget is ProductCard && widget.product.id == water.id,
    );
    await _tap(
      tester,
      find.descendant(of: waterCard, matching: find.text(water.name)),
    );
    expect(find.byType(ProductDetailScreen), findsOneWidget);
    final app = AppScope.of(tester.element(find.byType(ProductDetailScreen)));
    expect(find.text('Available to order'), findsOneWidget);
    await _tap(tester, find.byTooltip('Increase quantity'));
    await _tap(tester, find.text('Buy now'));
    expect(find.byType(CheckoutScreen), findsOneWidget);
    expect(app.quantityFor(water.id), 2);

    await _tap(tester, find.text('Choose saved address'));
    expect(find.byType(DeliveryAddressScreen), findsOneWidget);
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
      '560034',
    );
    await _tap(tester, find.text('Save and use address'));
    expect(find.byType(CheckoutScreen), findsOneWidget);
    expect(app.deliveryAddress.label, 'Work');

    await tester.enterText(
      find.widgetWithText(TextField, 'Promo code'),
      'PROTO10',
    );
    await _tap(tester, find.text('Apply code'));
    expect(app.couponDiscount, 18);
    final finalAmount = app.total;
    await _tap(tester, find.text('Place order'));
    expect(find.byType(OrderConfirmationScreen), findsOneWidget);
    expect(app.orders, hasLength(1));
    final order = app.orders.single;
    expect(order.total, finalAmount);
    expect(order.discount, 18);
    expect(order.promoCode, 'PROTO10');
    expect(order.address.label, 'Work');
    expect(order.items.single.quantity, 2);
    expect(app.cartCount, 0);
    expect(find.text(order.id), findsOneWidget);

    await _tap(tester, find.text('Track order'));
    expect(find.byType(OrderStatusScreen), findsOneWidget);
    for (final next in OrderStatus.values.skip(1)) {
      await _tap(tester, find.text('Advance demo status'));
      expect(app.orderById(order.id)!.status, next);
    }
    await _tap(tester, find.text('Continue shopping'));
    await _tap(tester, find.text('You').last);
    await _tap(tester, find.text('Your orders'));
    expect(find.byType(OrdersScreen), findsOneWidget);
    await _tap(tester, find.text(order.id));
    expect(find.byType(OrderStatusScreen), findsOneWidget);
    expect(app.orderById(order.id)!.discount, 18);
    expect(app.orderById(order.id)!.status, OrderStatus.delivered);
    expect(tester.takeException(), isNull);
  });
}

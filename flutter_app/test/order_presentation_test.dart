import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:proto/core/formatters/currency.dart';
import 'package:proto/core/state/app_controller.dart';
import 'package:proto/core/theme/proto_theme.dart';
import 'package:proto/core/widgets/proto_button.dart';
import 'package:proto/features/catalog/data/local_catalog_repository.dart';
import 'package:proto/features/orders/data/local_order_repository.dart';
import 'package:proto/features/orders/domain/order.dart';
import 'package:proto/features/orders/presentation/order_confirmation_screen.dart';
import 'package:proto/features/orders/presentation/order_status_screen.dart';
import 'package:proto/features/orders/presentation/orders_screen.dart';

void _viewport(WidgetTester tester, Size size) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> _show(
  WidgetTester tester,
  AppController controller,
  Widget home,
) async {
  await tester.pumpWidget(
    AppScope(
      controller: controller,
      child: MaterialApp(
        theme: ProtoTheme.theme,
        home: home,
        routes: {'/shop': (_) => const Scaffold(body: Text('Shop'))},
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
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

  late LocalOrderRepository repository;
  late AppController controller;

  setUp(() {
    repository = LocalOrderRepository(clock: () => DateTime(2026, 9, 30, 10));
    controller = AppController(orderRepository: repository);
    addTearDown(controller.dispose);
  });

  ProtoOrder order({double discount = 0, String? promoCode}) {
    final product = LocalCatalogRepository.products.first;
    return repository.create(
      items: [
        OrderItem(
          product: product,
          flavor: product.flavors.first,
          quantity: 2,
          unitPrice: product.price,
        ),
      ],
      address: controller.deliveryAddress,
      contact: controller.contact,
      paymentMethod: PaymentMethod.mockUpi,
      deliveryFee: 35,
      discount: discount,
      promoCode: promoCode,
    );
  }

  testWidgets('confirmation shows captured amounts, status, address and ETA', (
    tester,
  ) async {
    _viewport(tester, const Size(390, 844));
    final placed = order(discount: 150, promoCode: 'PROTO150');
    await _show(
      tester,
      controller,
      OrderConfirmationScreen(orderId: placed.id),
    );

    expect(find.text(placed.id), findsOneWidget);
    expect(find.text('Order Placed'), findsOneWidget);
    expect(find.text('Delivery fee'), findsWidgets);
    expect(find.text('Discount'), findsOneWidget);
    expect(find.text('PROTO150'), findsOneWidget);
    expect(find.text(formatPrice(placed.total)), findsWidgets);
    expect(find.text(placed.items.single.product.name), findsOneWidget);
    expect(find.text(placed.address.formatted), findsOneWidget);
    expect(find.text('Demo ETA · about 12 min'), findsOneWidget);

    await _tapVisible(tester, find.text('Track order'));
    expect(find.byType(OrderStatusScreen), findsOneWidget);
    expect(find.text('Confirmed'), findsOneWidget);
    expect(controller.orderById(placed.id)!.discount, 150);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tracking distinguishes completed, current and upcoming stages', (
    tester,
  ) async {
    _viewport(tester, const Size(390, 844));
    final placed = order(discount: 150, promoCode: 'PROTO150');
    await _show(tester, controller, OrderStatusScreen(orderId: placed.id));

    expect(find.text('Current demo stage'), findsOneWidget);
    expect(find.text('Next in the demo timeline'), findsNWidgets(4));
    expect(find.text('Completed in demo'), findsNothing);
    expect(find.text('Confirmed'), findsOneWidget);
    for (final next in OrderStatus.values.skip(1)) {
      await _tapVisible(tester, find.text('Advance demo status'));
      expect(controller.orderById(placed.id)!.status, next);
      expect(find.text('Current demo stage'), findsOneWidget);
      expect(find.text('Completed in demo'), findsNWidgets(next.index));
      expect(
        find.text('Next in the demo timeline'),
        findsNWidgets(OrderStatus.values.length - next.index - 1),
      );
    }
    final button = tester.widget<ProtoButton>(
      find.byWidgetPredicate(
        (widget) =>
            widget is ProtoButton && widget.label == 'Advance demo status',
      ),
    );
    expect(button.onPressed, isNull);
    expect(find.text(formatPrice(placed.total)), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('history keeps newest first and opens the order breakdown', (
    tester,
  ) async {
    _viewport(tester, const Size(390, 844));
    final first = order();
    final newest = order(discount: 150, promoCode: 'PROTO150');
    await _show(tester, controller, const OrdersScreen());

    expect(find.text(first.id), findsOneWidget);
    expect(find.text(newest.id), findsOneWidget);
    expect(find.text('View details'), findsNWidgets(2));
    expect(find.text('Order Placed'), findsNWidgets(2));
    final newestY = tester.getTopLeft(find.text(newest.id)).dy;
    final firstY = tester.getTopLeft(find.text(first.id)).dy;
    expect(newestY, lessThan(firstY));

    await _tapVisible(tester, find.text(newest.id));
    expect(find.byType(OrderStatusScreen), findsOneWidget);
    expect(find.text(newest.id), findsOneWidget);
    expect(find.text(newest.items.single.product.name), findsOneWidget);
    expect(find.text(newest.address.formatted), findsOneWidget);
    expect(find.text(formatPrice(newest.total)), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final size in [const Size(320, 640), const Size(1440, 900)]) {
    testWidgets('order surfaces render without overflow at $size', (
      tester,
    ) async {
      _viewport(tester, size);
      final placed = order(discount: 150, promoCode: 'PROTO150');
      await _show(
        tester,
        controller,
        OrderConfirmationScreen(orderId: placed.id),
      );
      expect(tester.takeException(), isNull);
      await _tapVisible(tester, find.text('Track order'));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await _show(tester, controller, const OrdersScreen());
      expect(tester.takeException(), isNull);
    });
  }
}

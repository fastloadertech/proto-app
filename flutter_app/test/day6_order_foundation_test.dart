import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:proto/core/formatters/currency.dart';
import 'package:proto/core/state/app_controller.dart';
import 'package:proto/core/theme/proto_theme.dart';
import 'package:proto/features/catalog/data/local_catalog_repository.dart';
import 'package:proto/features/catalog/domain/product.dart';
import 'package:proto/features/orders/data/local_order_repository.dart';
import 'package:proto/features/orders/domain/order.dart';
import 'package:proto/features/orders/domain/order_repository.dart';
import 'package:proto/features/orders/presentation/order_status_screen.dart';
import 'package:proto/features/orders/presentation/orders_screen.dart';
import 'package:proto/features/orders/presentation/widgets/order_timeline.dart';

final _placedAt = DateTime(2026, 10, 4, 12, 30);
final _product = LocalCatalogRepository.products.first;
const _address = DeliveryAddress(
  line1: '42, First Main Road',
  area: 'Indiranagar',
  city: 'Bengaluru',
  postalCode: '560038',
);
const _contact = CheckoutContact(name: 'Alex Rao', phone: '9876543210');

ProtoOrder _create(
  OrderRepository repository, {
  Product? product,
  int quantity = 2,
}) => repository.create(
  items: [
    OrderItem(
      product: product ?? _product,
      flavor: _product.flavors.first,
      quantity: quantity,
      unitPrice: product?.price ?? _product.price,
    ),
  ],
  address: _address,
  contact: _contact,
  paymentMethod: PaymentMethod.mockUpi,
  deliveryFee: 35,
);

Product _revisedProduct(Product product, List<String> flavors) => Product(
  id: product.id,
  name: 'Revised catalog name',
  brand: product.brand,
  categoryId: product.categoryId,
  price: product.price + 900,
  originalPrice: product.originalPrice + 900,
  weightLabel: product.weightLabel,
  subtitle: product.subtitle,
  description: product.description,
  proteinGrams: product.proteinGrams,
  servings: product.servings,
  rating: product.rating,
  reviewCount: product.reviewCount,
  badge: product.badge,
  accentColor: product.accentColor,
  form: product.form,
  flavors: flavors,
);

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

class _FlakyOrderRepository extends MockOrderRepository {
  _FlakyOrderRepository() : super(clock: () => _placedAt);

  Completer<ProtoOrder?>? delayedDetail;
  Completer<List<ProtoOrder>>? delayedHistory;
  bool failDetail = false;
  bool failHistory = false;

  @override
  Future<ProtoOrder?> loadById(String id) {
    if (delayedDetail != null) return delayedDetail!.future;
    if (failDetail) return Future.error(StateError('Demo read failed'));
    return super.loadById(id);
  }

  @override
  Future<List<ProtoOrder>> loadOrders() {
    if (delayedHistory != null) return delayedHistory!.future;
    if (failHistory) return Future.error(StateError('Demo read failed'));
    return super.loadOrders();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await (FontLoader(
      'Inter',
    )..addFont(rootBundle.load('assets/fonts/Inter.ttf'))).load();
  });

  test('order captures ID, time, prices, address, payment, and ETA', () {
    final repository = MockOrderRepository(clock: () => _placedAt);
    final order = _create(repository);
    final item = order.items.single;

    expect(order.id, 'PR-20261004-0001');
    expect(order.createdAt, _placedAt);
    expect(
      order.estimatedDeliveryAt,
      _placedAt.add(const Duration(minutes: 12)),
    );
    expect(item.productId, _product.id);
    expect(item.productName, _product.name);
    expect(item.quantity, 2);
    expect(item.unitPrice, _product.price);
    expect(item.subtotal, _product.price * 2);
    expect(order.subtotal, item.subtotal);
    expect(order.deliveryFee, 35);
    expect(order.total, item.subtotal + 35);
    expect(order.address.formatted, _address.formatted);
    expect(order.paymentMethod, PaymentMethod.mockUpi);
    expect(order.paymentStatus, PaymentStatus.notCharged);
    expect(order.status, OrderStatus.pending);
    expect(order.statusHistory, [OrderStatus.pending]);
    expect(() => order.items.add(item), throwsUnsupportedError);
    expect(
      () => order.statusHistory.add(OrderStatus.confirmed),
      throwsUnsupportedError,
    );
    expect(repository.getById(order.id), same(order));
    expect(_create(repository).id, 'PR-20261004-0002');
  });

  test('existing order stays unchanged when catalog data changes', () {
    final flavors = ['Chocolate'];
    final catalogProduct = _revisedProduct(_product, flavors);
    final repository = MockOrderRepository(clock: () => _placedAt);
    final first = _create(repository, product: catalogProduct);
    flavors.add('Vanilla');
    final secondCatalogProduct = _revisedProduct(_product, ['Strawberry']);
    final second = _create(repository, product: secondCatalogProduct);

    expect(first.items.single.productName, 'Revised catalog name');
    expect(first.items.single.unitPrice, catalogProduct.price);
    expect(first.items.single.product.flavors, ['Chocolate']);
    expect(
      () => first.items.single.product.flavors.add('Coffee'),
      throwsUnsupportedError,
    );
    expect(second.items.single.productId, first.items.single.productId);
    expect(first.total, catalogProduct.price * 2 + 35);
    expect(repository.getById(first.id)!.total, first.total);
  });

  test('controller preserves checkout snapshot and clears the bag', () {
    final controller = AppController(
      orderRepository: MockOrderRepository(clock: () => _placedAt),
    );
    addTearDown(controller.dispose);
    controller.add(_product, quantity: 2);
    final checkoutTotal = controller.total;
    final order = controller.placeOrder(
      address: _address,
      contact: _contact,
      paymentMethod: PaymentMethod.mockCard,
    );
    expect(order.total, checkoutTotal);
    expect(order.items.single.quantity, 2);
    expect(order.items.single.unitPrice, _product.price);
    expect(order.address.formatted, _address.formatted);
    expect(order.paymentMethod, PaymentMethod.mockCard);
    expect(order.paymentStatus, PaymentStatus.notCharged);
    expect(controller.cartCount, 0);
    expect(controller.orders.single.id, order.id);
    controller.saveDeliveryAddress(
      const DeliveryAddress(
        line1: '7, New Street',
        area: 'Koramangala',
        city: 'Bengaluru',
        postalCode: '560034',
      ),
    );
    expect(
      controller.orderById(order.id)!.address.formatted,
      _address.formatted,
    );
  });

  test('only adjacent delivery transitions are accepted', () {
    final repository = MockOrderRepository(clock: () => _placedAt);
    final order = _create(repository);
    expect(
      () => repository.updateStatus(order.id, OrderStatus.preparing),
      throwsStateError,
    );
    expect(repository.getById(order.id)!.status, OrderStatus.pending);
    for (final next in OrderStatus.deliveryStages.skip(1)) {
      expect(repository.updateStatus(order.id, next)!.status, next);
    }
    final delivered = repository.getById(order.id)!;
    expect(delivered.statusHistory, OrderStatus.deliveryStages);
    expect(delivered.deliveryAssignment!.driverName, 'Aarav Kumar');
    expect(delivered.deliveryAssignment!.vehicleType, 'Electric scooter');
    expect(delivered.deliveryAssignment!.vehicleDetails, 'KA 03 AB 2468');
    expect(repository.advanceStatus(order.id), same(delivered));
    expect(() => repository.cancel(order.id), throwsStateError);
    expect(
      () => repository.updateStatus(order.id, OrderStatus.pending),
      throwsStateError,
    );
    expect(repository.updateStatus('missing', OrderStatus.confirmed), isNull);
  });

  test('cancellation is terminal and limited to Pending or Confirmed', () {
    final repository = MockOrderRepository(clock: () => _placedAt);
    final pending = _create(repository);
    expect(repository.cancel(pending.id)!.statusHistory, [
      OrderStatus.pending,
      OrderStatus.cancelled,
    ]);
    expect(repository.advanceStatus(pending.id)!.status, OrderStatus.cancelled);
    final confirmed = _create(repository);
    repository.updateStatus(confirmed.id, OrderStatus.confirmed);
    expect(repository.cancel(confirmed.id)!.status, OrderStatus.cancelled);
    final preparing = _create(repository);
    repository.updateStatus(preparing.id, OrderStatus.confirmed);
    repository.updateStatus(preparing.id, OrderStatus.preparing);
    expect(() => repository.cancel(preparing.id), throwsStateError);
    expect(repository.getById(preparing.id)!.status, OrderStatus.preparing);
    expect(repository.cancel('missing'), isNull);
    repository.reset();
    expect(repository.orders, isEmpty);
    expect(repository.getById(pending.id), isNull);
  });

  testWidgets('cancelled timeline is terminal and order stays in history', (
    tester,
  ) async {
    _viewport(tester, const Size(390, 844));
    final repository = MockOrderRepository(clock: () => _placedAt);
    final order = _create(repository);
    final controller = AppController(orderRepository: repository);
    addTearDown(controller.dispose);
    await _show(tester, controller, OrderStatusScreen(orderId: order.id));
    expect(find.byType(OrderTimeline), findsOneWidget);
    await tester.ensureVisible(find.text('Cancel order'));
    await tester.tap(find.text('Cancel order'));
    await tester.pumpAndSettle();
    expect(find.text('Cancel this order?'), findsOneWidget);
    await tester.tap(find.text('Cancel order').last);
    await tester.pumpAndSettle();
    expect(controller.orderById(order.id)!.status, OrderStatus.cancelled);
    expect(find.text('Cancelled'), findsWidgets);
    expect(find.text('Preparing'), findsNothing);
    expect(find.text('Driver assigned'), findsNothing);
    await _show(tester, controller, const OrdersScreen());
    expect(find.text(order.id), findsOneWidget);
    expect(find.text('Cancelled'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Out for Delivery shows mock driver and item unit prices', (
    tester,
  ) async {
    _viewport(tester, const Size(390, 844));
    final repository = MockOrderRepository(clock: () => _placedAt);
    final order = _create(repository);
    repository.updateStatus(order.id, OrderStatus.confirmed);
    repository.updateStatus(order.id, OrderStatus.preparing);
    repository.updateStatus(order.id, OrderStatus.outForDelivery);
    final controller = AppController(orderRepository: repository);
    addTearDown(controller.dispose);
    await _show(tester, controller, OrderStatusScreen(orderId: order.id));
    expect(find.text('Out for Delivery'), findsWidgets);
    expect(find.text('Driver assigned'), findsOneWidget);
    expect(find.text('Aarav Kumar'), findsOneWidget);
    expect(find.textContaining('Electric scooter'), findsOneWidget);
    expect(find.textContaining('Estimated arrival'), findsOneWidget);
    expect(find.text('${formatPrice(_product.price)} each'), findsOneWidget);
    expect(find.text('Payment status · Not charged · demo'), findsOneWidget);
    await tester.ensureVisible(find.text('Contact driver'));
    await tester.tap(find.text('Contact driver'));
    await tester.pump();
    expect(find.textContaining('No call was placed'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('detail loading, error, retry, and not-found are recoverable', (
    tester,
  ) async {
    _viewport(tester, const Size(390, 844));
    final repository = _FlakyOrderRepository();
    final order = _create(repository);
    repository.delayedDetail = Completer<ProtoOrder?>();
    final controller = AppController(orderRepository: repository);
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      AppScope(
        controller: controller,
        child: MaterialApp(
          theme: ProtoTheme.theme,
          home: OrderStatusScreen(orderId: order.id),
        ),
      ),
    );
    expect(find.text('Finding your order…'), findsOneWidget);
    repository.delayedDetail!.completeError(StateError('Demo read failed'));
    await tester.pumpAndSettle();
    expect(
      find.text('Order details are unavailable right now.'),
      findsOneWidget,
    );
    repository.delayedDetail = null;
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(find.text(order.id), findsOneWidget);
    await _show(
      tester,
      controller,
      const OrderStatusScreen(orderId: 'does-not-exist'),
    );
    expect(find.text('Order unavailable'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('history loading and error show retry', (tester) async {
    _viewport(tester, const Size(390, 844));
    final repository = _FlakyOrderRepository();
    final order = _create(repository);
    repository.delayedHistory = Completer<List<ProtoOrder>>();
    final controller = AppController(orderRepository: repository);
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      AppScope(
        controller: controller,
        child: MaterialApp(theme: ProtoTheme.theme, home: const OrdersScreen()),
      ),
    );
    expect(find.text('Finding your orders…'), findsOneWidget);
    repository.delayedHistory!.completeError(StateError('Demo read failed'));
    await tester.pumpAndSettle();
    expect(find.text('Orders are unavailable right now.'), findsOneWidget);
    repository.delayedHistory = null;
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(find.text(order.id), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final size in [const Size(320, 640), const Size(1440, 900)]) {
    testWidgets('Day 6 order details fit $size', (tester) async {
      _viewport(tester, size);
      final repository = MockOrderRepository(clock: () => _placedAt);
      final order = _create(repository);
      repository.updateStatus(order.id, OrderStatus.confirmed);
      repository.updateStatus(order.id, OrderStatus.preparing);
      repository.updateStatus(order.id, OrderStatus.outForDelivery);
      final controller = AppController(orderRepository: repository);
      addTearDown(controller.dispose);
      await _show(tester, controller, OrderStatusScreen(orderId: order.id));
      expect(tester.takeException(), isNull);
    });
  }
}

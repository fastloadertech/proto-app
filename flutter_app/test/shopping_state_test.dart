import 'package:flutter_test/flutter_test.dart';
import 'package:proto/core/state/app_controller.dart';
import 'package:proto/core/state/delivery_pricing.dart';
import 'package:proto/features/catalog/data/local_catalog_repository.dart';
import 'package:proto/features/orders/data/local_order_repository.dart';
import 'package:proto/features/orders/domain/order.dart';

void main() {
  late AppController app;
  final placedAt = DateTime(2026, 9, 29, 10);
  final whey = LocalCatalogRepository.products.first;
  final water = LocalCatalogRepository.getById('hydration-water')!;

  setUp(
    () => app = AppController(
      orderRepository: LocalOrderRepository(clock: () => placedAt),
    ),
  );
  tearDown(() => app.dispose());

  ProtoOrder place({PaymentMethod method = PaymentMethod.cashOnDelivery}) =>
      app.placeOrder(
        address: app.deliveryAddress,
        contact: app.contact,
        paymentMethod: method,
      );

  test('delivery policy is consistent at the free-delivery boundary', () {
    expect(DeliveryPricing.feeFor(0), 0);
    expect(DeliveryPricing.feeFor(498), 35);
    expect(DeliveryPricing.feeFor(499), 0);
    expect(app.total, 0);
    app.add(water);
    expect(app.deliveryFee, 35);
    expect(app.total, water.price + 35);
    app.add(water, quantity: 5);
    expect(app.deliveryFee, 0);
    expect(app.total, water.price * 6);
  });

  test('bulk add and whole-line removal preserve other flavor variants', () {
    app.add(whey, flavor: whey.flavors.first, quantity: 3);
    app.add(whey, flavor: whey.flavors.last, quantity: 2);
    app.removeLine(whey, flavor: whey.flavors.first);
    expect(app.cartCount, 2);
    expect(app.bagLines.single.flavor, whey.flavors.last);
    expect(app.total, whey.price * 2);
    app.removeLine(whey, flavor: whey.flavors.first);
    expect(app.cartCount, 2);
    app.removeLine(whey, flavor: whey.flavors.last);
    expect(app.bagLines, isEmpty);
    expect(app.total, 0);
  });

  test('invalid quantity or flavor never changes the bag', () {
    expect(() => app.add(whey, quantity: 0), throwsArgumentError);
    expect(() => app.add(whey, quantity: -2), throwsArgumentError);
    expect(
      () => app.add(whey, flavor: 'Unavailable flavor'),
      throwsArgumentError,
    );
    expect(app.bagLines, isEmpty);
  });

  test(
    'placing an order captures prices, flavors, fees, and contact before clearing the bag',
    () {
      app.add(water, flavor: water.flavors.last, quantity: 2);
      final expectedTotal = app.total;
      final order = place(method: PaymentMethod.mockUpi);
      expect(order.id, 'PR-20260929-0001');
      expect(order.createdAt, placedAt);
      expect(
        order.estimatedDeliveryAt,
        placedAt.add(const Duration(minutes: 12)),
      );
      expect(order.items.single.flavor, water.flavors.last);
      expect(order.items.single.quantity, 2);
      expect(order.items.single.unitPrice, water.price);
      expect(order.deliveryFee, 35);
      expect(order.total, expectedTotal);
      expect(order.contact.phone, app.contact.phone);
      expect(order.paymentMethod, PaymentMethod.mockUpi);
      expect(order.status, OrderStatus.orderPlaced);
      expect(app.cartCount, 0);
      expect(app.total, 0);
      expect(app.orders, [order]);
      expect(order.items.clear, throwsUnsupportedError);
      expect(() => app.orders.clear(), throwsUnsupportedError);

      app.add(whey, quantity: 3);
      app.setLocation('Koramangala, Bengaluru');
      expect(order.total, expectedTotal);
      expect(order.address.area, 'Indiranagar');
      expect(order.items, hasLength(1));
    },
  );

  test('empty or invalid checkout creates no order and preserves the bag', () {
    expect(place, throwsStateError);
    app.add(water);
    expect(
      () => app.placeOrder(
        address: app.deliveryAddress,
        contact: const CheckoutContact(name: 'A', phone: '123'),
        paymentMethod: PaymentMethod.mockCard,
      ),
      throwsArgumentError,
    );
    expect(
      () => app.placeOrder(
        address: const DeliveryAddress(
          line1: '',
          area: '',
          city: '',
          postalCode: '000000',
        ),
        contact: app.contact,
        paymentMethod: PaymentMethod.cashOnDelivery,
      ),
      throwsArgumentError,
    );
    expect(app.orders, isEmpty);
    expect(app.cartCount, 1);
    expect(place().id, 'PR-20260929-0001');
    expect(place, throwsStateError);
    expect(app.orders, hasLength(1));
  });

  test('orders receive unique IDs, newest first, with immutable details', () {
    app.add(water);
    final first = place();
    app.add(whey);
    final second = app.placeOrder(
      address: const DeliveryAddress(
        line1: ' 18, Main Road ',
        area: ' HSR Layout ',
        city: ' Bengaluru ',
        postalCode: ' 560102 ',
      ),
      contact: const CheckoutContact(
        name: ' Demo Shopper ',
        phone: ' 9876543210 ',
        email: ' shopper@example.test ',
      ),
      paymentMethod: PaymentMethod.mockCard,
    );
    expect(first.id, isNot(second.id));
    expect(app.orders.map((order) => order.id), [second.id, first.id]);
    expect(second.address.line1, '18, Main Road');
    expect(second.contact.name, 'Demo Shopper');
    expect(app.deliveryAddress, second.address);
    expect(app.contact, second.contact);
    expect(app.paymentMethod, PaymentMethod.mockCard);
    expect(app.orderById(first.id), same(first));
  });

  test('mock status moves through all five steps and stays delivered', () {
    app.add(water);
    final order = place();
    var updates = 0;
    app.addListener(() => updates++);
    for (final status in OrderStatus.values.skip(1)) {
      expect(app.advanceOrderStatus(order.id)!.status, status);
      expect(app.orderById(order.id)!.status, status);
    }
    expect(updates, 4);
    expect(order.status, OrderStatus.orderPlaced);
    expect(app.advanceOrderStatus(order.id)!.status, OrderStatus.delivered);
    expect(updates, 4);
    expect(app.advanceOrderStatus('unknown'), isNull);
    expect(updates, 4);
    expect(app.orders, hasLength(1));
  });

  test('address and contact validation accept local sample details', () {
    expect(app.deliveryAddress.isValid, isTrue);
    expect(app.contact.isValid, isTrue);
    expect(
      const CheckoutContact(
        name: 'Demo',
        phone: '9876543210',
        email: 'invalid',
      ).isValid,
      isFalse,
    );
    expect(
      const CheckoutContact(
        name: 'Demo',
        phone: '9876543210',
        email: 'demo@example.test',
      ).isValid,
      isTrue,
    );
  });
}

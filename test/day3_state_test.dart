import 'package:flutter_test/flutter_test.dart';
import 'package:proto/core/state/app_controller.dart';
import 'package:proto/core/state/coupon_pricing.dart';
import 'package:proto/core/state/delivery_pricing.dart';
import 'package:proto/features/catalog/data/local_catalog_repository.dart';
import 'package:proto/features/orders/data/local_order_repository.dart';
import 'package:proto/features/orders/domain/order.dart';

void main() {
  final whey = LocalCatalogRepository.products.first;
  final water = LocalCatalogRepository.getById('hydration-water')!;
  late AppController app;

  setUp(() {
    app = AppController(
      orderRepository: LocalOrderRepository(
        clock: () => DateTime(2026, 9, 30, 12),
      ),
    );
  });
  tearDown(() => app.dispose());

  test(
    'mock coupon rules are deterministic, bounded, and case-insensitive',
    () {
      expect(
        CouponPricing.evaluate('PROTO10', 0).status,
        CouponStatus.emptyBag,
      );
      final tenPercent = CouponPricing.evaluate(' proto10 ', 2499);
      expect(tenPercent.code, 'PROTO10');
      expect(tenPercent.status, CouponStatus.applied);
      expect(tenPercent.discount, 250);
      expect(CouponPricing.evaluate('PROTO10', 89).discount, 9);

      expect(
        CouponPricing.evaluate('FUEL50', 498).status,
        CouponStatus.minimumNotMet,
      );
      expect(CouponPricing.evaluate('fuel50', 499).discount, 50);
      expect(
        CouponPricing.evaluate('EXPIRED', 500).status,
        CouponStatus.expired,
      );
      expect(
        CouponPricing.evaluate('UNKNOWN', 500).status,
        CouponStatus.invalid,
      );
    },
  );

  test('saved Home, Work, and Other addresses are selected and normalized', () {
    expect(app.savedAddresses.map((address) => address.label), ['Home']);
    const work = DeliveryAddress(
      line1: ' 18, Training Lane ',
      area: ' HSR Layout ',
      city: ' Bengaluru ',
      postalCode: ' 560102 ',
      label: 'Work',
    );
    app.saveDeliveryAddress(work);
    expect(app.deliveryAddress.line1, '18, Training Lane');
    expect(app.deliveryAddress.label, 'Work');
    expect(app.savedAddresses, hasLength(2));
    app.saveDeliveryAddress(
      const DeliveryAddress(
        line1: '14, Test Street',
        area: 'Koramangala',
        city: 'Bengaluru',
        postalCode: '560034',
        label: 'Other',
      ),
    );
    expect(app.savedAddresses, hasLength(3));
    app.selectDeliveryAddress('Home');
    expect(app.location, 'Indiranagar, Bengaluru');
    app.setLocation('Koramangala, Bengaluru');
    expect(app.deliveryAddress.area, 'Koramangala');
    expect(app.savedAddresses.first.area, 'Koramangala');
    app.selectDeliveryAddress('Work');
    expect(app.deliveryAddress.area, 'HSR Layout');
    expect(app.deliveryAddress.postalCode, '560102');
    expect(() => app.savedAddresses.clear(), throwsUnsupportedError);
    expect(() => app.selectDeliveryAddress('Unknown'), throwsArgumentError);
    expect(
      () => app.saveDeliveryAddress(
        const DeliveryAddress(
          line1: 'x',
          area: '',
          city: '',
          postalCode: '000000',
          label: 'Work',
        ),
      ),
      throwsArgumentError,
    );
    expect(
      () => app.saveDeliveryAddress(
        const DeliveryAddress(
          line1: '25, Test Street',
          area: 'HSR Layout',
          city: 'Bengaluru',
          postalCode: '560102',
          label: 'Custom',
        ),
      ),
      throwsArgumentError,
    );
    expect(app.savedAddresses, hasLength(3));
  });

  test('coupon feedback and totals update with bag changes', () {
    expect(app.applyCoupon('PROTO10'), isFalse);
    expect(app.couponMessage, contains('Add products'));
    app.add(water, quantity: 6);
    expect(app.subtotal, 534);
    expect(app.deliveryFee, 0);
    expect(app.applyCoupon(' fuel50 '), isTrue);
    expect(app.couponCode, 'FUEL50');
    expect(app.couponDiscount, 50);
    expect(app.total, 484);

    app.remove(water);
    expect(app.subtotal, 445);
    expect(app.deliveryFee, DeliveryPricing.standardFee);
    expect(app.couponDiscount, 0);
    expect(app.total, 480);
    app.add(water);
    expect(app.couponDiscount, 50);
    expect(app.total, 484);

    expect(app.applyCoupon('EXPIRED'), isFalse);
    expect(app.couponMessage, contains('expired'));
    expect(app.couponCode, 'FUEL50');
    expect(app.applyCoupon('nonsense'), isFalse);
    expect(app.couponMessage, contains('not available'));
    expect(app.couponCode, 'FUEL50');
    app.removeCoupon();
    expect(app.couponCode, isNull);
    expect(app.couponMessage, isNull);
    expect(app.total, 534);
    expect(app.applyCoupon(''), isFalse);
    expect(app.couponMessage, contains('Enter'));
  });

  test(
    'order snapshots coupon, address, fee, total, and resets the coupon',
    () {
      app.add(water, quantity: 6);
      app.saveDeliveryAddress(
        const DeliveryAddress(
          line1: '18, Training Lane',
          area: 'HSR Layout',
          city: 'Bengaluru',
          postalCode: '560102',
          label: 'Work',
        ),
      );
      expect(app.applyCoupon('FUEL50'), isTrue);
      final expected = app.total;
      final order = app.placeOrder(
        address: app.deliveryAddress,
        contact: app.contact,
        paymentMethod: PaymentMethod.mockUpi,
      );
      expect(order.id, 'PR-20260930-0001');
      expect(order.promoCode, 'FUEL50');
      expect(order.discount, 50);
      expect(order.deliveryFee, 0);
      expect(order.total, expected);
      expect(order.address.label, 'Work');
      expect(order.status, OrderStatus.pending);
      expect(app.bagLines, isEmpty);
      expect(app.couponCode, isNull);
      expect(app.couponDiscount, 0);
      expect(app.savedAddresses, hasLength(2));
      app.add(whey);
      expect(order.total, expected);
      expect(order.items.single.quantity, 6);
      final confirmed = app.advanceOrderStatus(order.id)!;
      expect(confirmed.status, OrderStatus.confirmed);
      expect(confirmed.discount, 50);
      expect(confirmed.promoCode, 'FUEL50');
      expect(confirmed.total, expected);
    },
  );

  test('invalid discount cannot make a mock order negative', () {
    final repo = LocalOrderRepository();
    final item = OrderItem(
      product: water,
      flavor: water.flavors.first,
      quantity: 1,
      unitPrice: water.price,
    );
    expect(
      () => repo.create(
        items: [item],
        address: app.deliveryAddress,
        contact: app.contact,
        paymentMethod: PaymentMethod.cashOnDelivery,
        deliveryFee: 35,
        discount: water.price + 1,
        promoCode: 'PROTO10',
      ),
      throwsArgumentError,
    );
    expect(
      () => repo.create(
        items: [item],
        address: app.deliveryAddress,
        contact: app.contact,
        paymentMethod: PaymentMethod.cashOnDelivery,
        deliveryFee: 35,
        discount: -1,
      ),
      throwsArgumentError,
    );
    expect(repo.orders, isEmpty);
  });
}

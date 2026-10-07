import 'package:flutter_test/flutter_test.dart';
import 'package:proto/core/api/api_config.dart';
import 'package:proto/core/api/api_failure.dart';
import 'package:proto/core/api/api_models.dart';
import 'package:proto/core/api/order_api_contract.dart';
import 'package:proto/core/state/app_controller.dart';
import 'package:proto/features/auth/data/local_auth_repository.dart';
import 'package:proto/features/auth/domain/auth_repository.dart';
import 'package:proto/features/catalog/data/local_catalog_repository.dart';
import 'package:proto/features/catalog/domain/catalog_repository.dart';
import 'package:proto/features/orders/data/local_order_repository.dart';
import 'package:proto/features/orders/domain/order.dart';
import 'package:proto/features/orders/domain/order_repository.dart';

void main() {
  test('customer, session, category, product and address JSON round-trip', () {
    const customer = CustomerDto(id: 'c1', name: 'Alex', phone: '9876543210');
    final session = AuthSessionDto(
      customer: customer,
      accessToken: 'test-token',
      expiresAt: DateTime.utc(2030, 1, 2),
    );
    expect(
      AuthSessionDto.fromJson(session.toJson()).toJson(),
      session.toJson(),
    );
    expect(CustomerDto.fromJson(customer.toJson()).toJson(), customer.toJson());
    const category = CategoryDto(id: 'protein', name: 'Protein');
    expect(CategoryDto.fromJson(category.toJson()).toJson(), category.toJson());
    const product = ProductDto(
      id: 'whey',
      categoryId: 'protein',
      name: 'Whey',
      description: 'Protein powder',
      pricePaise: 249900,
      available: true,
      type: 'tub',
      flavors: ['Chocolate'],
    );
    expect(ProductDto.fromJson(product.toJson()).toJson(), product.toJson());
    const address = AddressDto(
      id: 'a1',
      label: 'Home',
      line1: '42 Main Road',
      area: 'Indiranagar',
      city: 'Bengaluru',
      postalCode: '560038',
    );
    expect(AddressDto.fromJson(address.toJson()).toJson(), address.toJson());
  });

  test('order and delivery JSON preserve snapshot, paise and driver job', () {
    const address = AddressDto(
      id: 'a1',
      label: 'Home',
      line1: '42 Main Road',
      area: 'Indiranagar',
      city: 'Bengaluru',
      postalCode: '560038',
    );
    final order = OrderDto(
      id: 'P-1',
      createdAt: DateTime.utc(2026, 10, 4),
      status: 'out_for_delivery',
      items: const [
        OrderItemDto(
          productId: 'whey',
          name: 'Whey',
          quantity: 2,
          unitPricePaise: 249900,
          flavor: 'Chocolate',
        ),
      ],
      address: address,
      payment: const PaymentDto(
        method: 'cash_on_delivery',
        status: 'not_charged',
      ),
      subtotalPaise: 499800,
      deliveryFeePaise: 0,
      discountPaise: 0,
      totalPaise: 499800,
      driver: DriverAssignmentDto(
        deliveryJobId: 'L-100',
        driverName: 'Aarav',
        vehicle: 'Electric scooter',
        contact: '9000000000',
        eta: DateTime.utc(2026, 10, 4, 12),
      ),
    );
    final restored = OrderDto.fromJson(order.toJson());
    expect(restored.toJson(), order.toJson());
    expect(restored.driver?.deliveryJobId, 'L-100');
    expect(restored.items.single.quantity, 2);
  });

  test(
    'create order request carries choices without client-supplied totals',
    () {
      const request = CreateOrderRequestDto(
        addressId: 'a1',
        paymentMethod: 'cash_on_delivery',
        items: [
          CreateOrderLineDto(
            productId: 'whey',
            quantity: 2,
            flavor: 'Chocolate',
          ),
        ],
        promoCode: 'PROTO10',
      );
      expect(
        CreateOrderRequestDto.fromJson(request.toJson()).toJson(),
        request.toJson(),
      );
      expect(request.toJson().containsKey('totalPaise'), isFalse);
    },
  );

  test('repository boundaries retain local sources and support injection', () {
    CatalogRepository catalog = const LocalCatalogSource();
    OrderRepository orders = LocalOrderRepository();
    AuthRepository auth = LocalAuthRepository();
    final app = AppController(
      catalogRepository: catalog,
      orderRepository: orders,
      authRepository: auth,
    );
    expect(identical(app.catalog, catalog), isTrue);
    expect(
      app.catalog
          .byCategory('protein')
          .every((product) => product.categoryId == 'protein'),
      isTrue,
    );
    expect(app.catalog.browse(query: 'Whey'), isNotEmpty);
    expect(app.orders, isEmpty);
    app.dispose();
  });

  test('local auth is token-free, validates phone and logs out', () async {
    AuthRepository auth = LocalAuthRepository();
    expect(auth.currentSession, isNull);
    await expectLater(auth.login('123'), throwsArgumentError);
    final session = await auth.login('9876543210');
    expect(session.phone, '9876543210');
    expect(session.isAuthenticated, isFalse);
    expect(session.authorizationHeaders, isEmpty);
    expect(auth.currentSession, same(session));
    await auth.logout();
    expect(auth.currentSession, isNull);
  });

  test('API error categories, routes and development config', () {
    expect(ApiFailure.fromStatus(null).kind, ApiFailureKind.network);
    expect(ApiFailure.fromStatus(401).kind, ApiFailureKind.authentication);
    expect(ApiFailure.fromStatus(404).kind, ApiFailureKind.notFound);
    expect(ApiFailure.fromStatus(422).kind, ApiFailureKind.validation);
    expect(ApiFailure.fromStatus(503).kind, ApiFailureKind.server);
    expect(ApiFailure.fromStatus(418).kind, ApiFailureKind.unknown);
    expect(OrderApiContract.orderPath('a/b'), endsWith('/a%2Fb'));
    expect(OrderApiContract.cancelPath('123'), endsWith('/123/cancel'));
    expect(OrderApiContract.statusPath('123'), endsWith('/123/status'));
    expect(ApiConfig.baseUrl, isNotEmpty);
  });

  test(
    'failed asynchronous order submission retains bag and address',
    () async {
      final app = AppController(orderRepository: _RejectingOrderRepository());
      final destination = app.deliveryAddress;
      app.add(LocalCatalogRepository.products.first);
      await expectLater(
        app.submitOrder(
          address: destination,
          contact: app.contact,
          paymentMethod: app.paymentMethod,
        ),
        throwsA(isA<ApiFailure>()),
      );
      expect(app.cartCount, 1);
      expect(app.orders, isEmpty);
      expect(app.deliveryAddress, same(destination));
      app.dispose();
    },
  );

  test('local delivery assignment carries a stable mock job ID', () {
    final app = AppController();
    app.add(LocalCatalogRepository.products.first);
    final order = app.placeOrder(
      address: app.deliveryAddress,
      contact: app.contact,
      paymentMethod: app.paymentMethod,
    );
    app.advanceOrderStatus(order.id);
    app.advanceOrderStatus(order.id);
    final dispatched = app.advanceOrderStatus(order.id)!;
    expect(dispatched.status, OrderStatus.outForDelivery);
    expect(dispatched.deliveryAssignment?.deliveryJobId, 'DEMO-${order.id}');
    app.dispose();
  });
}

class _RejectingOrderRepository extends LocalOrderRepository {
  @override
  Future<ProtoOrder> createAsync({
    required List<OrderItem> items,
    required DeliveryAddress address,
    required CheckoutContact contact,
    required PaymentMethod paymentMethod,
    required double deliveryFee,
    double discount = 0,
    String? promoCode,
  }) async => throw const ApiFailure(ApiFailureKind.network);
}

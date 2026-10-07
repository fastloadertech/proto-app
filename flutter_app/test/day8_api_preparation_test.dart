import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:proto/core/api/api_client.dart';
import 'package:proto/core/api/api_config.dart';
import 'package:proto/core/api/api_failure.dart';
import 'package:proto/core/api/api_models.dart';
import 'package:proto/core/api/api_routes.dart';
import 'package:proto/core/api/money_codec.dart';
import 'package:proto/core/api/shared_backend_contract.dart';
import 'package:proto/core/state/app_controller.dart';
import 'package:proto/features/auth/data/api_auth_repository.dart';
import 'package:proto/features/auth/domain/auth_repository.dart';
import 'package:proto/features/catalog/data/api_catalog_repository.dart';
import 'package:proto/features/catalog/data/local_catalog_repository.dart';
import 'package:proto/features/catalog/domain/catalog_repository.dart';
import 'package:proto/features/checkout/presentation/checkout_screen.dart';
import 'package:proto/features/orders/data/api_order_repository.dart';
import 'package:proto/features/orders/domain/order_repository.dart';

void main() {
  test('environment config validates development and production URLs', () {
    const dev = ApiConfig(developmentBaseUrl: 'http://localhost:3101/');
    expect(
      dev.resolve(ApiRoutes.orders).toString(),
      'http://localhost:3101/api/v1/customer/orders',
    );
    const prod = ApiConfig(
      environment: ApiEnvironment.production,
      productionBaseUrl: 'https://api.example.test',
    );
    expect(prod.resolve(ApiRoutes.products).scheme, 'https');
    expect(
      () => const ApiConfig(
        environment: ApiEnvironment.production,
      ).resolve(ApiRoutes.orders),
      throwsStateError,
    );
    expect(() => dev.resolve('/v1/customer/orders'), throwsArgumentError);
  });

  test('NestJS failures map each status and validation arrays', () {
    expect(ApiFailure.fromStatus(null).kind, ApiFailureKind.network);
    expect(ApiFailure.fromStatus(400).kind, ApiFailureKind.validation);
    expect(ApiFailure.fromStatus(401).kind, ApiFailureKind.authentication);
    expect(ApiFailure.fromStatus(403).kind, ApiFailureKind.forbidden);
    expect(ApiFailure.fromStatus(404).kind, ApiFailureKind.notFound);
    expect(ApiFailure.fromStatus(409).kind, ApiFailureKind.conflict);
    expect(ApiFailure.fromStatus(500).kind, ApiFailureKind.server);
    expect(ApiFailure.fromStatus(418).kind, ApiFailureKind.unknown);
    final failure = ApiFailure.fromResponse(400, {
      'statusCode': 400,
      'error': 'Bad Request',
      'message': ['phone must be valid', 'addressId is required'],
    });
    expect(failure.details, hasLength(2));
    expect(failure.message, contains('addressId'));
  });

  test(
    'Prisma Decimal, customer, category, product and address map safely',
    () {
      expect(MoneyCodec.paiseFromRupees('2499.05'), 249905);
      expect(MoneyCodec.rupeesFromPaise(249905), '2499.05');
      expect(() => MoneyCodec.paiseFromRupees('1.234'), throwsFormatException);
      final customer = SharedBackendContract.customer(_customer);
      expect(CustomerDto.fromJson(customer.toJson()).phone, '9876543210');
      final category = SharedBackendContract.category(_category);
      expect(CategoryDto.fromJson(category.toJson()).slug, 'protein');
      final product = SharedBackendContract.product(_product);
      expect(ProductDto.fromJson(product.toJson()).pricePaise, 249900);
      expect(product.available, isTrue);
      final address = SharedBackendContract.address(_address);
      expect(AddressDto.fromJson(address.toJson()).userId, 'c1');
      expect(address.line2, 'Indiranagar');
    },
  );

  test('order, item, payment, delivery and driver contract round-trip', () {
    final dto = SharedBackendContract.order(_backendOrder);
    final restored = OrderDto.fromJson(dto.toJson());
    expect(restored.toJson(), dto.toJson());
    expect(dto.reference, 'PR-100');
    expect(dto.items.single.lineTotalPaise, 249900);
    expect(dto.payment?.amountPaise, 249900);
    expect(dto.delivery?.id, 'job-1');
    expect(dto.driver?.driverName, 'Aarav');
    expect(dto.driver?.vehicle, contains('SCOOTER'));
  });

  test('API client uses /api/v1, bearer header and stable errors', () async {
    final transport = _RecordingTransport(
      (request) async => const ApiResponse(200, {'ok': true}),
    );
    final client = ApiClient(transport: transport);
    expect(await client.get(ApiRoutes.authMe, accessToken: 'test-token'), {
      'ok': true,
    });
    expect(transport.requests.single.uri.path, ApiRoutes.authMe);
    expect(
      transport.requests.single.headers['Authorization'],
      'Bearer test-token',
    );
    transport.handler = (request) async => const ApiResponse(403, {
      'statusCode': 403,
      'error': 'Forbidden',
      'message': 'No access',
    });
    await expectLater(
      client.get(ApiRoutes.orders),
      throwsA(
        isA<ApiFailure>().having(
          (e) => e.kind,
          'kind',
          ApiFailureKind.forbidden,
        ),
      ),
    );
    transport.handler = (request) async => throw StateError('offline');
    await expectLater(
      client.get(ApiRoutes.orders),
      throwsA(
        isA<ApiFailure>().having((e) => e.kind, 'kind', ApiFailureKind.network),
      ),
    );
  });

  test('API auth adapter is opt-in and keeps a replaceable session', () async {
    const session = CustomerLoginDto(
      user: CustomerDto(
        id: 'c1',
        name: 'Alex Rao',
        phone: '+15550001001',
        role: 'CUSTOMER',
        isActive: true,
      ),
      accessToken: 'test-token',
      role: 'CUSTOMER',
    );
    final transport = _RecordingTransport(
      (request) async => ApiResponse(200, session.toJson()),
    );
    AuthRepository auth = ApiAuthRepository(ApiClient(transport: transport));
    expect(auth.currentSession, isNull);
    final signedIn = await auth.login('+15550001001', code: '123456');
    expect(signedIn.authorizationHeaders['Authorization'], 'Bearer test-token');
    expect(transport.requests.first.uri.path, ApiRoutes.authLogin);
    await auth.logout();
    expect(auth.currentSession, isNull);
  });

  test(
    'API catalog cache supports discovery and survives refresh failure',
    () async {
      final transport = _RecordingTransport(
        (request) async => ApiResponse(
          200,
          request.uri.path == ApiRoutes.categories
              ? [_category]
              : [
                  _product,
                  {
                    ..._product,
                    'id': 'p2',
                    'name': 'Budget Whey',
                    'price': '999.00',
                    'isActive': false,
                  },
                ],
        ),
      );
      CatalogRepository catalog = ApiCatalogRepository(
        ApiClient(transport: transport),
      );
      final api = catalog as ApiCatalogRepository;
      expect(api.isLoaded, isFalse);
      await api.refresh();
      expect(api.isLoaded, isTrue);
      expect(catalog.browse(query: 'whey'), hasLength(2));
      expect(catalog.browse(availableOnly: true), hasLength(1));
      expect(catalog.browse(sort: CatalogSort.priceLow).first.price, 999);
      transport.handler = (request) async => const ApiResponse(500, {
        'statusCode': 500,
        'message': 'Internal server error.',
      });
      await expectLater(api.refresh(), throwsA(isA<ApiFailure>()));
      expect(catalog.products, hasLength(2));
      transport.handler = (request) async => ApiResponse(
        200,
        request.uri.path == ApiRoutes.categories
            ? [
                {..._category, 'isActive': false},
              ]
            : [_product],
      );
      await api.refresh();
      expect(catalog.categories, isEmpty);
      expect(catalog.products, isEmpty);
    },
  );

  test('API order failure keeps bag and retry creates one order', () async {
    var fail = true;
    final transport = _RecordingTransport((request) async {
      if (fail)
        return const ApiResponse(409, {
          'statusCode': 409,
          'message': 'Inventory changed.',
        });
      return ApiResponse(201, _backendOrder);
    });
    final auth = _FixedAuth();
    OrderRepository orders = ApiOrderRepository(
      client: ApiClient(transport: transport),
      auth: auth,
      catalog: const LocalCatalogSource(),
    );
    final app = AppController(orderRepository: orders);
    app.add(LocalCatalogRepository.products.first);
    final address = app.deliveryAddress;
    await expectLater(
      app.submitOrder(
        address: address,
        contact: app.contact,
        paymentMethod: app.paymentMethod,
      ),
      throwsA(
        isA<ApiFailure>().having(
          (e) => e.kind,
          'kind',
          ApiFailureKind.conflict,
        ),
      ),
    );
    expect(app.cartCount, 1);
    expect(app.orders, isEmpty);
    expect(app.deliveryAddress, same(address));
    fail = false;
    final created = await app.submitOrder(
      address: address,
      contact: app.contact,
      paymentMethod: app.paymentMethod,
    );
    expect(created.id, 'order-1');
    expect(app.cartCount, 0);
    expect(app.orders.single.id, created.id);
    final request = transport.requests.last;
    expect(request.uri.path, ApiRoutes.orders);
    expect(request.headers['Authorization'], 'Bearer test-token');
    final body = Map<String, dynamic>.from(request.body as Map);
    expect(body['paymentMethod'], 'CASH_ON_DELIVERY');
    expect(body.containsKey('totalPaise'), isFalse);
    expect(body.containsKey('deliveryFee'), isFalse);
    app.dispose();
  });

  testWidgets('checkout shows API failure and allows a successful retry', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    var fail = true;
    final transport = _RecordingTransport(
      (request) async => fail
          ? const ApiResponse(409, {
              'statusCode': 409,
              'message': 'Inventory changed.',
            })
          : ApiResponse(201, _backendOrder),
    );
    final app = AppController(
      orderRepository: ApiOrderRepository(
        client: ApiClient(transport: transport),
        auth: _FixedAuth(),
        catalog: const LocalCatalogSource(),
      ),
    );
    addTearDown(app.dispose);
    app.add(LocalCatalogRepository.products.first);
    await tester.pumpWidget(
      AppScope(
        controller: app,
        child: const MaterialApp(home: CheckoutScreen()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Place order'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Place order'));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();
    expect(find.text('Inventory changed.'), findsOneWidget);
    expect(find.text('Place order'), findsOneWidget);
    expect(app.cartCount, 1);
    fail = false;
    await tester.ensureVisible(find.text('Place order'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Place order'));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();
    expect(find.text('Order placed'), findsWidgets);
    expect(app.cartCount, 0);
  });
}

class _RecordingTransport implements ApiTransport {
  _RecordingTransport(this.handler);
  Future<ApiResponse> Function(ApiRequest) handler;
  final List<ApiRequest> requests = [];
  @override
  Future<ApiResponse> send(ApiRequest request) {
    requests.add(request);
    return handler(request);
  }
}

class _FixedAuth implements AuthRepository {
  @override
  CustomerSession? get currentSession => CustomerSession(
    customerId: 'c1',
    phone: '9876543210',
    accessToken: 'test-token',
    expiresAt: DateTime.utc(2035),
  );
  @override
  Future<CustomerSession> login(String phone, {String? code}) async =>
      currentSession!;

  @override
  Future<CustomerSession?> restoreSession() async => currentSession;
  @override
  Future<void> logout() async {}
}

final JsonMap _customer = {
  'id': 'c1',
  'name': 'Alex Rao',
  'phone': '9876543210',
};
final JsonMap _category = {
  'id': 'cat-1',
  'name': 'Protein',
  'slug': 'protein',
  'isActive': true,
};
final JsonMap _product = {
  'id': 'whey-isolate',
  'categoryId': 'cat-1',
  'sku': 'WHEY-1',
  'name': 'Whey Isolate',
  'description': 'Clean protein',
  'price': '2499.00',
  'currency': 'INR',
  'isActive': true,
};
final JsonMap _address = {
  'id': 'address-1',
  'userId': 'c1',
  'label': 'Home',
  'line1': '42 First Main Road',
  'line2': 'Indiranagar',
  'city': 'Bengaluru',
  'postalCode': '560038',
  'isDefault': true,
  'recipientName': 'Alex Rao',
  'phone': '9876543210',
};
final JsonMap _backendOrder = {
  'id': 'order-1',
  'reference': 'PR-100',
  'customerId': 'c1',
  'customer': _customer,
  'status': 'PLACED',
  'createdAt': '2026-10-05T10:00:00.000Z',
  'subtotal': '2499.00',
  'deliveryFee': '0.00',
  'total': '2499.00',
  'items': [
    {
      'id': 'line-1',
      'productId': 'whey-isolate',
      'productName': 'Whey Isolate',
      'quantity': 1,
      'unitPrice': '2499.00',
      'lineTotal': '2499.00',
    },
  ],
  'deliveryAddress': _address,
  'payment': {
    'id': 'pay-1',
    'method': 'CASH_ON_DELIVERY',
    'status': 'PENDING',
    'amount': '2499.00',
    'currency': 'INR',
  },
  'deliveryJob': {
    'id': 'job-1',
    'orderId': 'order-1',
    'status': 'REQUESTED',
    'estimatedMinutes': 12,
    'driver': {'name': 'Aarav', 'phone': '9000000000'},
    'vehicle': {
      'vehicleType': 'SCOOTER',
      'registrationNumber': 'KA 03 AB 2468',
    },
  },
};

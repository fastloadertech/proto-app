import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:proto/app/proto_app.dart';
import 'package:proto/core/api/api_client.dart';
import 'package:proto/core/api/api_failure.dart';
import 'package:proto/core/api/api_routes.dart';
import 'package:proto/core/api/live_order_contract.dart';
import 'package:proto/core/state/app_controller.dart';
import 'package:proto/features/auth/domain/auth_repository.dart';
import 'package:proto/features/catalog/data/local_catalog_repository.dart';
import 'package:proto/features/checkout/presentation/checkout_screen.dart';
import 'package:proto/features/orders/data/api_order_repository.dart';
import 'package:proto/features/orders/domain/order.dart';
import 'package:proto/features/orders/presentation/order_status_screen.dart';
import 'package:proto/features/orders/presentation/orders_screen.dart';

final _product = LocalCatalogRepository.products.first;
const _address = DeliveryAddress(
  id: 'saved-1',
  label: 'Gym',
  line1: '42 First Main Road',
  area: 'Indiranagar',
  city: 'Bengaluru',
  postalCode: '560038',
);
const _contact = CheckoutContact(name: 'Alex Rao', phone: '9876543210');

Map<String, dynamic> _order({
  String id = 'order-1',
  String status = 'PENDING',
  String unitPrice = '1499.95',
  String lineTotal = '2999.90',
  String subtotal = '2999.90',
  String total = '2999.90',
  String createdAt = '2026-10-08T10:00:00.000Z',
}) => {
  'id': id,
  'reference': 'PR-1001',
  'status': status,
  'subtotal': subtotal,
  'deliveryFee': '0.00',
  'total': total,
  'currency': 'INR',
  'deliveryAddress': {
    'line1': _address.line1,
    'line2': _address.area,
    'city': _address.city,
    'state': null,
    'postalCode': _address.postalCode,
    'recipientName': _contact.name,
    'phone': '+919876543210',
  },
  'items': [
    {
      'id': 'item-1',
      'productId': _product.id,
      'productName': 'Backend product snapshot',
      'unitPrice': unitPrice,
      'quantity': 2,
      'lineTotal': lineTotal,
    },
  ],
  'createdAt': createdAt,
  'updatedAt': '2026-10-08T10:01:00.000Z',
};

class _Transport implements ApiTransport {
  _Transport(this.handler);
  Future<ApiResponse> Function(ApiRequest) handler;
  final requests = <ApiRequest>[];
  @override
  Future<ApiResponse> send(ApiRequest request) {
    requests.add(request);
    return handler(request);
  }
}

class _Auth implements AuthRepository {
  CustomerSession? session = const CustomerSession(
    customerId: 'customer-1',
    phone: '+15550001001',
    name: 'Alex Rao',
    accessToken: 'test-token',
  );
  @override
  CustomerSession? get currentSession => session;
  @override
  Future<CustomerSession> login(String phone, {String? code}) async {
    session = CustomerSession(
      customerId: 'customer-1',
      phone: phone,
      accessToken: 'test-token',
    );
    return session!;
  }

  @override
  Future<void> logout() async => session = null;
  @override
  Future<CustomerSession?> restoreSession() async => session;
}

ApiOrderRepository _repository(_Transport transport, _Auth auth) =>
    ApiOrderRepository(
      client: ApiClient(transport: transport),
      auth: auth,
      catalog: const LocalCatalogSource(),
    );

void main() {
  test('real order contract round-trips decimal money and address', () {
    final dto = LiveOrderDto.fromJson(_order());
    expect(dto.subtotalPaise, 299990);
    expect(dto.items.single.unitPricePaise, 149995);
    expect(dto.items.single.lineTotalPaise, 299990);
    expect(dto.address.line2, 'Indiranagar');
    expect(LiveOrderDto.fromJson(dto.toJson()).toJson(), dto.toJson());
    final bad = _order()..['total'] = '2999.91';
    expect(() => LiveOrderDto.fromJson(bad), throwsFormatException);
  });

  test('create sends authenticated IDs, quantities and address only', () async {
    final transport = _Transport((_) async => ApiResponse(201, _order()));
    final auth = _Auth();
    final repo = _repository(transport, auth);
    final selected = OrderItem(
      product: _product,
      flavor: null,
      quantity: 2,
      unitPrice: _product.price,
    );
    final created = await repo.createAsync(
      items: [selected],
      address: _address,
      contact: _contact,
      paymentMethod: PaymentMethod.mockUpi,
      deliveryFee: 99,
      discount: 50,
      promoCode: 'PROTO10',
    );
    final request = transport.requests.single;
    expect(request.method, ApiMethod.post);
    expect(request.uri.path, ApiRoutes.orders);
    expect(request.headers['Authorization'], 'Bearer test-token');
    expect(request.body, {
      'items': [
        {'productId': _product.id, 'quantity': 2},
      ],
      'deliveryAddress': {
        'line1': _address.line1,
        'line2': _address.area,
        'city': _address.city,
        'state': null,
        'postalCode': _address.postalCode,
        'recipientName': _contact.name,
        'phone': '+919876543210',
      },
    });
    expect(created.id, 'order-1');
    expect(created.isLive, isTrue);
    expect(created.status, OrderStatus.pending);
    expect(created.subtotal, 2999.90);
    expect(created.deliveryFee, 0);
    expect(created.total, 2999.90);
    expect(created.items.single.productName, 'Backend product snapshot');
    expect(created.items.single.product.price, 1499.95);
    expect(created.items.single.unitPrice, 1499.95);
    expect(created.items.single.total, 2999.90);
    expect(created.address.area, _address.area);
    expect(created.updatedAt, DateTime.utc(2026, 10, 8, 10, 1));
    expect(created.paymentMethod, PaymentMethod.mockUpi);
  });

  test('bag variants combine into one backend item', () async {
    final transport = _Transport((_) async => ApiResponse(201, _order()));
    final repo = _repository(transport, _Auth());
    final item = OrderItem(
      product: _product,
      flavor: null,
      quantity: 1,
      unitPrice: _product.price,
    );
    await repo.createAsync(
      items: [item, item],
      address: _address,
      contact: _contact,
      paymentMethod: PaymentMethod.cashOnDelivery,
      deliveryFee: 0,
    );
    final body = Map<String, dynamic>.from(
      transport.requests.single.body as Map,
    );
    expect(body['items'], [
      {'productId': _product.id, 'quantity': 2},
    ]);
  });

  test('history sorts newest first and detail loads from API', () async {
    final transport = _Transport((request) async {
      if (request.uri.path == ApiRoutes.orders) {
        return ApiResponse(200, [
          _order(id: 'older', createdAt: '2026-10-07T10:00:00.000Z'),
          _order(id: 'newer'),
        ]);
      }
      return ApiResponse(200, _order(id: 'older', status: 'CONFIRMED'));
    });
    final repo = _repository(transport, _Auth());
    expect((await repo.loadOrders()).map((order) => order.id), [
      'newer',
      'older',
    ]);
    final detail = await repo.loadById('older');
    expect(detail?.status, OrderStatus.confirmed);
    expect(detail?.items.single.productName, 'Backend product snapshot');
    expect(repo.getById('older')?.status, OrderStatus.confirmed);
    expect(transport.requests.last.uri.path, ApiRoutes.order('older'));
    expect(
      transport.requests.every((r) => r.headers.containsKey('Authorization')),
      isTrue,
    );
  });

  test('every backend status maps to the live timeline', () async {
    final statuses = <String, OrderStatus>{
      'PENDING': OrderStatus.pending,
      'CONFIRMED': OrderStatus.confirmed,
      'PREPARING': OrderStatus.preparing,
      'READY_FOR_PICKUP': OrderStatus.readyForPickup,
      'PICKED_UP': OrderStatus.pickedUp,
      'OUT_FOR_DELIVERY': OrderStatus.outForDelivery,
      'DELIVERED': OrderStatus.delivered,
      'CANCELLED': OrderStatus.cancelled,
    };
    for (final entry in statuses.entries) {
      final repo = _repository(
        _Transport((_) async => ApiResponse(200, _order(status: entry.key))),
        _Auth(),
      );
      final order = await repo.loadById('order-1');
      expect(order?.status, entry.value, reason: entry.key);
      expect(order?.statusHistory.last, entry.value);
    }
  });

  test('auth and API failures never replace a valid cached order', () async {
    var status = 200;
    final transport = _Transport(
      (_) async => status == 200
          ? ApiResponse(200, _order())
          : ApiResponse(status, const {}),
    );
    final auth = _Auth();
    final repo = _repository(transport, auth);
    await repo.loadById('order-1');
    for (final entry in <int, ApiFailureKind>{
      400: ApiFailureKind.validation,
      401: ApiFailureKind.authentication,
      403: ApiFailureKind.forbidden,
      404: ApiFailureKind.notFound,
      409: ApiFailureKind.conflict,
      500: ApiFailureKind.server,
    }.entries) {
      status = entry.key;
      await expectLater(
        repo.loadById('order-1'),
        throwsA(isA<ApiFailure>().having((e) => e.kind, 'kind', entry.value)),
      );
      expect(repo.getById('order-1')?.status, OrderStatus.pending);
    }
    auth.session = null;
    final requestsBefore = transport.requests.length;
    await expectLater(
      repo.loadOrders(),
      throwsA(
        isA<ApiFailure>().having(
          (e) => e.kind,
          'kind',
          ApiFailureKind.authentication,
        ),
      ),
    );
    expect(transport.requests.length, requestsBefore);
  });

  test('network and malformed responses are safe failures', () async {
    final auth = _Auth();
    final network = _repository(
      _Transport((_) async => throw Exception('offline')),
      auth,
    );
    await expectLater(
      network.loadOrders(),
      throwsA(
        isA<ApiFailure>().having((e) => e.kind, 'kind', ApiFailureKind.network),
      ),
    );
    final malformed = _repository(
      _Transport((_) async => ApiResponse(200, _order()..remove('updatedAt'))),
      auth,
    );
    await expectLater(
      malformed.loadById('order-1'),
      throwsA(
        isA<ApiFailure>().having((e) => e.kind, 'kind', ApiFailureKind.unknown),
      ),
    );
  });

  test(
    'bag clears only after successful live order, local mode stays local',
    () async {
      var fail = true;
      final transport = _Transport(
        (_) async => fail
            ? const ApiResponse(409, {'message': 'Inventory changed.'})
            : ApiResponse(201, _order()),
      );
      final app = AppController(
        orderRepository: _repository(transport, _Auth()),
      );
      addTearDown(app.dispose);
      expect(app.liveOrders, isTrue);
      app.add(_product, quantity: 2);
      await expectLater(
        app.submitOrder(
          address: app.deliveryAddress,
          contact: app.contact,
          paymentMethod: app.paymentMethod,
        ),
        throwsA(isA<ApiFailure>()),
      );
      expect(app.cartCount, 2);
      expect(app.orders, isEmpty);
      fail = false;
      final order = await app.submitOrder(
        address: app.deliveryAddress,
        contact: app.contact,
        paymentMethod: app.paymentMethod,
      );
      expect(app.cartCount, 0);
      expect(order.id, 'order-1');
      expect(app.orders.single.id, 'order-1');
      final local = AppController();
      addTearDown(local.dispose);
      expect(local.liveOrders, isFalse);
      local.add(_product);
      final localOrder = await local.submitOrder(
        address: local.deliveryAddress,
        contact: local.contact,
        paymentMethod: local.paymentMethod,
      );
      expect(localOrder.isLive, isFalse);
      expect(localOrder.id, startsWith('PR-'));
    },
  );

  testWidgets('checkout shows safe retry and backend confirmation', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var fail = true;
    final transport = _Transport(
      (_) async => fail
          ? const ApiResponse(409, {'message': 'Inventory changed.'})
          : ApiResponse(201, _order()),
    );
    final app = AppController(orderRepository: _repository(transport, _Auth()));
    addTearDown(app.dispose);
    app.add(_product, quantity: 2);
    await tester.pumpWidget(
      AppScope(
        controller: app,
        child: const MaterialApp(home: CheckoutScreen()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Place order'));
    await tester.tap(find.text('Place order'));
    await tester.pumpAndSettle();
    expect(find.textContaining('quantity is unavailable'), findsOneWidget);
    expect(app.cartCount, 2);
    fail = false;
    await tester.ensureVisible(find.text('Place order'));
    await tester.tap(find.text('Place order'));
    await tester.pumpAndSettle();
    expect(find.text('Order placed'), findsWidgets);
    expect(find.text('order-1'), findsWidgets);
    expect(app.cartCount, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('live-orders flag selects API repository', (tester) async {
    final transport = _Transport(
      (request) async => request.uri.path == ApiRoutes.orders
          ? const ApiResponse(200, [])
          : ApiResponse(200, _order()),
    );
    await tester.pumpWidget(
      ProtoApp(
        liveOrders: true,
        authRepository: _Auth(),
        catalogRepository: const LocalCatalogSource(),
        apiTransport: transport,
      ),
    );
    final app = tester.widget<AppScope>(find.byType(AppScope)).notifier!;
    expect(app.liveOrders, isTrue);
    await app.loadOrders();
    expect(transport.requests.single.uri.path, ApiRoutes.orders);
  });

  testWidgets('live history opens backend detail with a seven-stage timeline', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final transport = _Transport(
      (request) async => request.uri.path == ApiRoutes.orders
          ? ApiResponse(200, [_order()])
          : ApiResponse(200, _order()),
    );
    final app = AppController(orderRepository: _repository(transport, _Auth()));
    addTearDown(app.dispose);
    await tester.pumpWidget(
      AppScope(
        controller: app,
        child: const MaterialApp(home: OrdersScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('order-1'), findsOneWidget);
    await tester.tap(find.text('order-1'));
    await tester.pumpAndSettle();
    expect(find.byType(OrderStatusScreen), findsOneWidget);
    expect(find.text('Pending'), findsWidgets);
    expect(find.text('Ready for Pickup'), findsOneWidget);
    expect(find.text('Picked Up'), findsOneWidget);
    expect(find.text('Refresh status'), findsOneWidget);
    expect(find.text('Advance demo status'), findsNothing);
    expect(find.text('Cancel order'), findsNothing);
    expect(transport.requests.last.uri.path, ApiRoutes.order('order-1'));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'manual live status refresh reloads detail without demo controls',
    (tester) async {
      var status = 'PENDING';
      final transport = _Transport(
        (_) async => ApiResponse(200, _order(status: status)),
      );
      final app = AppController(
        orderRepository: _repository(transport, _Auth()),
      );
      addTearDown(app.dispose);
      await tester.pumpWidget(
        AppScope(
          controller: app,
          child: const MaterialApp(home: OrderStatusScreen(orderId: 'order-1')),
        ),
      );
      await tester.pumpAndSettle();
      expect(app.orderById('order-1')?.status, OrderStatus.pending);
      status = 'READY_FOR_PICKUP';
      await tester.ensureVisible(find.text('Refresh status'));
      await tester.tap(find.text('Refresh status'));
      await tester.pumpAndSettle();
      expect(app.orderById('order-1')?.status, OrderStatus.readyForPickup);
      expect(find.text('Ready for Pickup'), findsWidgets);
      expect(transport.requests.length, 2);
      expect(tester.takeException(), isNull);
    },
  );
}

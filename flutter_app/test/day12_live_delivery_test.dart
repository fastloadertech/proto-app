import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:proto/core/api/api_client.dart';
import 'package:proto/core/api/api_config.dart';
import 'package:proto/core/api/api_routes.dart';
import 'package:proto/core/api/live_delivery_contract.dart';
import 'package:proto/core/api/live_order_contract.dart';
import 'package:proto/core/state/app_controller.dart';
import 'package:proto/features/auth/domain/auth_repository.dart';
import 'package:proto/features/catalog/data/local_catalog_repository.dart';
import 'package:proto/features/orders/data/api_order_repository.dart';
import 'package:proto/features/orders/domain/delivery_status.dart';
import 'package:proto/features/orders/domain/order.dart';
import 'package:proto/features/orders/presentation/order_status_screen.dart';
import 'package:proto/features/orders/presentation/widgets/delivery_progress_card.dart';

const _stamp = '2026-10-10T09:00:00.000Z';

Map<String, dynamic> _order({Object? delivery, String status = 'PENDING'}) => {
  'id': 'order-1',
  'reference': 'PR-1',
  'status': status,
  'subtotal': '100.00',
  'deliveryFee': '10.00',
  'total': '110.00',
  'currency': 'INR',
  'deliveryAddress': {
    'line1': '42 Main Road',
    'line2': 'Indiranagar',
    'city': 'Bengaluru',
    'state': null,
    'postalCode': '560038',
    'recipientName': 'Alex',
    'phone': '+919876543210',
  },
  'items': [
    {
      'id': 'line-1',
      'productId': 'product-1',
      'productName': 'Protein',
      'unitPrice': '100.00',
      'quantity': 1,
      'lineTotal': '100.00',
    },
  ],
  'createdAt': _stamp,
  'updatedAt': _stamp,
  'delivery': delivery,
};

Map<String, dynamic> _delivery(String status) => {
  'id': 'delivery-1',
  'orderId': 'order-1',
  'status': status,
  'driverId': null,
  'createdAt': _stamp,
  'updatedAt': _stamp,
  'assignedAt': null,
  'acceptedAt': null,
  'pickedUpAt': null,
  'deliveredAt': null,
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
    phone: '+919876543210',
    accessToken: 'customer-token',
  );
  @override
  CustomerSession? get currentSession => session;
  @override
  Future<CustomerSession> login(String phone, {String? code}) async => session!;
  @override
  Future<void> logout() async => session = null;
  @override
  Future<CustomerSession?> restoreSession() async => session;
}

ApiOrderRepository _repository(
  _Transport transport,
  _Auth auth, {
  bool liveDelivery = true,
}) => ApiOrderRepository(
  client: ApiClient(transport: transport),
  auth: auth,
  catalog: const LocalCatalogSource(),
  loadDeliveryStatus: liveDelivery,
);

void main() {
  test('delivery flag is opt-in and routes stay under the shared API', () {
    expect(ApiConfig.liveDeliveryStatus, isFalse);
    expect(ApiRoutes.delivery('one/two'), '/api/v1/deliveries/one%2Ftwo');
  });

  test('order link and delivery DTO serialize independently', () {
    final order = LiveOrderDto.fromJson(
      _order(delivery: {'id': 'delivery-1', 'status': 'AVAILABLE'}),
    );
    expect(order.delivery?.id, 'delivery-1');
    expect(LiveOrderDto.fromJson(order.toJson()).delivery?.status, 'AVAILABLE');
    final dto = LiveDeliveryDto.fromJson(_delivery('PICKED_UP'));
    expect(LiveDeliveryDto.fromJson(dto.toJson()).status, 'PICKED_UP');
  });

  test(
    'all backend delivery statuses map without invented driver data',
    () async {
      const values = {
        'REQUESTED': DeliveryStatus.requested,
        'AVAILABLE': DeliveryStatus.available,
        'DRIVER_ASSIGNED': DeliveryStatus.driverAssigned,
        'DRIVER_ARRIVING': DeliveryStatus.driverArriving,
        'ARRIVED_AT_PICKUP': DeliveryStatus.arrivedAtPickup,
        'ACCEPTED': DeliveryStatus.accepted,
        'PICKED_UP': DeliveryStatus.pickedUp,
        'ON_THE_WAY': DeliveryStatus.onTheWay,
        'IN_TRANSIT': DeliveryStatus.inTransit,
        'OUT_FOR_DELIVERY': DeliveryStatus.outForDelivery,
        'DELIVERED': DeliveryStatus.delivered,
        'CANCELLED': DeliveryStatus.cancelled,
      };
      for (final entry in values.entries) {
        final transport = _Transport(
          (request) async => ApiResponse(
            200,
            request.uri.path == ApiRoutes.order('order-1')
                ? _order(delivery: {'id': 'delivery-1', 'status': entry.key})
                : _delivery(entry.key),
          ),
        );
        final order = await _repository(transport, _Auth()).loadById('order-1');
        expect(order?.delivery?.status, entry.value);
        expect(order?.delivery?.hasDetails, isTrue);
        expect(order?.deliveryAssignment, isNull);
        expect(
          transport.requests.map((r) => r.method),
          everyElement(ApiMethod.get),
        );
        expect(transport.requests.map((r) => r.uri.path), [
          ApiRoutes.order('order-1'),
          ApiRoutes.delivery('delivery-1'),
        ]);
        expect(
          transport.requests.every(
            (r) => r.headers['Authorization'] == 'Bearer customer-token',
          ),
          isTrue,
        );
      }
    },
  );

  test('missing link and disabled flag never request delivery', () async {
    final transport = _Transport((_) async => ApiResponse(200, _order()));
    final repo = _repository(transport, _Auth());
    expect((await repo.loadById('order-1'))?.delivery, isNull);
    expect(transport.requests.length, 1);
    final mockTransport = _Transport(
      (_) async => ApiResponse(
        200,
        _order(delivery: {'id': 'delivery-1', 'status': 'AVAILABLE'}),
      ),
    );
    final mockRepo = _repository(mockTransport, _Auth(), liveDelivery: false);
    expect(mockRepo.deliveryStatusEnabled, isFalse);
    expect((await mockRepo.loadById('order-1'))?.delivery?.hasDetails, isFalse);
    expect(mockTransport.requests.length, 1);
  });

  test('refresh fetches changed delivery status', () async {
    var status = 'AVAILABLE';
    final transport = _Transport(
      (request) async => ApiResponse(
        200,
        request.uri.path == ApiRoutes.order('order-1')
            ? _order(delivery: {'id': 'delivery-1', 'status': status})
            : _delivery(status),
      ),
    );
    final repo = _repository(transport, _Auth());
    expect(
      (await repo.loadById('order-1'))?.delivery?.status,
      DeliveryStatus.available,
    );
    status = 'ACCEPTED';
    expect(
      (await repo.loadById('order-1'))?.delivery?.status,
      DeliveryStatus.accepted,
    );
    expect(repo.getById('order-1')?.delivery?.status, DeliveryStatus.accepted);
    expect(transport.requests.length, 4);
  });

  test('delivery errors preserve order and linked status for retry', () async {
    for (final entry in <int, DeliveryIssue>{
      401: DeliveryIssue.authentication,
      403: DeliveryIssue.authentication,
      404: DeliveryIssue.missing,
      500: DeliveryIssue.server,
    }.entries) {
      final transport = _Transport(
        (request) async => request.uri.path == ApiRoutes.order('order-1')
            ? ApiResponse(
                200,
                _order(delivery: {'id': 'delivery-1', 'status': 'AVAILABLE'}),
              )
            : ApiResponse(entry.key, {'message': 'Unavailable'}),
      );
      final order = await _repository(transport, _Auth()).loadById('order-1');
      expect(order?.delivery?.status, DeliveryStatus.available);
      expect(order?.deliveryIssue, entry.value);
      expect(order?.items.single.productName, 'Protein');
    }
    final network = _Transport((request) async {
      if (request.uri.path == ApiRoutes.order('order-1')) {
        return ApiResponse(
          200,
          _order(delivery: {'id': 'delivery-1', 'status': 'AVAILABLE'}),
        );
      }
      throw Exception('offline');
    });
    expect(
      (await _repository(network, _Auth()).loadById('order-1'))?.deliveryIssue,
      DeliveryIssue.network,
    );
  });

  test('mismatched delivery never replaces linked order data', () async {
    final transport = _Transport(
      (request) async => ApiResponse(
        200,
        request.uri.path == ApiRoutes.order('order-1')
            ? _order(delivery: {'id': 'delivery-1', 'status': 'AVAILABLE'})
            : (_delivery('DELIVERED')..['orderId'] = 'another-order'),
      ),
    );
    final order = await _repository(transport, _Auth()).loadById('order-1');
    expect(order?.delivery?.status, DeliveryStatus.available);
    expect(order?.deliveryIssue, DeliveryIssue.invalid);
  });

  test('expired session stops before any request', () async {
    final transport = _Transport((_) async => ApiResponse(200, _order()));
    final auth = _Auth()..session = null;
    await expectLater(
      _repository(transport, auth).loadById('order-1'),
      throwsException,
    );
    expect(transport.requests, isEmpty);
  });

  testWidgets('mobile delivery card shows unassigned and retryable failure', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final transport = _Transport(
      (request) async => ApiResponse(200, _order(delivery: null)),
    );
    final repo = _repository(transport, _Auth());
    final unassigned = (await repo.loadById('order-1'))!;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: DeliveryProgressCard(order: unassigned, onRetry: () {}),
          ),
        ),
      ),
    );
    expect(
      find.text('No delivery has been linked to this order yet.'),
      findsOneWidget,
    );
    expect(find.text('Check again'), findsOneWidget);
    expect(tester.takeException(), isNull);

    transport.handler = (request) async =>
        request.uri.path == ApiRoutes.order('order-1')
        ? ApiResponse(
            200,
            _order(delivery: {'id': 'delivery-1', 'status': 'AVAILABLE'}),
          )
        : const ApiResponse(503, {'message': 'Unavailable'});
    final failed = (await repo.loadById('order-1'))!;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: DeliveryProgressCard(order: failed, onRetry: () {}),
          ),
        ),
      ),
    );
    expect(find.text('Awaiting a delivery partner'), findsWidgets);
    expect(find.text('Retry delivery status'), findsOneWidget);
    expect(tester.takeException(), isNull);

    transport.handler = (request) async =>
        request.uri.path == ApiRoutes.order('order-1')
        ? ApiResponse(
            200,
            _order(delivery: {'id': 'delivery-1', 'status': 'AVAILABLE'}),
          )
        : const ApiResponse(401, {'message': 'Expired'});
    final expired = (await repo.loadById('order-1'))!;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: DeliveryProgressCard(order: expired, onRetry: () {}),
          ),
        ),
      ),
    );
    expect(find.text('Sign in again'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test(
    'failed delivery refresh retains detailed status and timestamps',
    () async {
      var round = 0;
      final transport = _Transport((request) async {
        if (request.uri.path == ApiRoutes.order('order-1')) {
          return ApiResponse(
            200,
            _order(
              status: round == 0 ? 'PICKED_UP' : 'OUT_FOR_DELIVERY',
              delivery: {
                'id': 'delivery-1',
                'status': round == 0 ? 'PICKED_UP' : 'OUT_FOR_DELIVERY',
              },
            ),
          );
        }
        if (round == 1) return const ApiResponse(503, {'message': 'Offline'});
        return ApiResponse(
          200,
          _delivery(round == 0 ? 'PICKED_UP' : 'OUT_FOR_DELIVERY')
            ..['pickedUpAt'] = _stamp,
        );
      });
      final repo = _repository(transport, _Auth());
      final first = (await repo.loadById('order-1'))!;
      expect(first.delivery?.pickedUpAt, isNotNull);
      round = 1;
      final failed = (await repo.loadById('order-1'))!;
      expect(failed.status, OrderStatus.outForDelivery);
      expect(failed.delivery?.status, DeliveryStatus.pickedUp);
      expect(failed.delivery?.pickedUpAt, first.delivery?.pickedUpAt);
      expect(failed.delivery?.hasDetails, isTrue);
      expect(failed.deliveryIssue, DeliveryIssue.server);
      round = 2;
      final retried = (await repo.loadById('order-1'))!;
      expect(retried.delivery?.status, DeliveryStatus.outForDelivery);
      expect(retried.deliveryIssue, isNull);
    },
  );

  test('older slower detail response cannot overwrite a newer one', () async {
    final firstResponse = Completer<ApiResponse>();
    final secondResponse = Completer<ApiResponse>();
    var orderRequests = 0;
    var deliveryRequests = 0;
    final transport = _Transport((request) {
      if (request.uri.path == ApiRoutes.order('order-1')) {
        orderRequests++;
        return orderRequests == 1
            ? firstResponse.future
            : secondResponse.future;
      }
      deliveryRequests++;
      return Future.value(
        ApiResponse(
          200,
          _delivery(deliveryRequests == 1 ? 'DELIVERED' : 'AVAILABLE'),
        ),
      );
    });
    final repo = _repository(transport, _Auth());
    final older = repo.loadById('order-1');
    final newer = repo.loadById('order-1');
    secondResponse.complete(
      ApiResponse(
        200,
        _order(
          status: 'DELIVERED',
          delivery: {'id': 'delivery-1', 'status': 'DELIVERED'},
        ),
      ),
    );
    expect((await newer)?.delivery?.status, DeliveryStatus.delivered);
    firstResponse.complete(
      ApiResponse(
        200,
        _order(delivery: {'id': 'delivery-1', 'status': 'AVAILABLE'}),
      ),
    );
    expect((await older)?.delivery?.status, DeliveryStatus.delivered);
    expect(repo.getById('order-1')?.status, OrderStatus.delivered);
    expect(repo.getById('order-1')?.delivery?.status, DeliveryStatus.delivered);
  });

  test(
    'a history response arriving after reset does not restore orders',
    () async {
      final pending = Completer<ApiResponse>();
      final transport = _Transport((_) => pending.future);
      final repo = _repository(transport, _Auth());
      final history = repo.loadOrders();
      repo.reset();
      pending.complete(ApiResponse(200, [_order()]));
      expect(await history, isEmpty);
      expect(repo.orders, isEmpty);
    },
  );

  testWidgets('initial loading, initial error and retry remain distinct', (
    tester,
  ) async {
    final pending = Completer<ApiResponse>();
    final transport = _Transport((_) => pending.future);
    final app = AppController(orderRepository: _repository(transport, _Auth()));
    addTearDown(app.dispose);
    await tester.pumpWidget(
      AppScope(
        controller: app,
        child: const MaterialApp(home: OrderStatusScreen(orderId: 'order-1')),
      ),
    );
    expect(find.text('Finding your order…'), findsOneWidget);
    pending.complete(const ApiResponse(503, {'message': 'Unavailable'}));
    await tester.pumpAndSettle();
    expect(
      find.text('Order details are unavailable right now.'),
      findsOneWidget,
    );
    transport.handler = (_) async => ApiResponse(200, _order());
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(
      find.text('No delivery has been linked to this order yet.'),
      findsOneWidget,
    );
    expect(find.text('Order details are unavailable right now.'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'refresh keeps status visible, ignores repeat taps, and retries',
    (tester) async {
      final pending = Completer<ApiResponse>();
      var refreshPending = false;
      var retry = false;
      final transport = _Transport((request) {
        if (request.uri.path == ApiRoutes.order('order-1')) {
          if (refreshPending) return pending.future;
          return Future.value(
            ApiResponse(
              200,
              _order(
                status: retry ? 'CONFIRMED' : 'PENDING',
                delivery: {
                  'id': 'delivery-1',
                  'status': retry ? 'ACCEPTED' : 'AVAILABLE',
                },
              ),
            ),
          );
        }
        return Future.value(
          ApiResponse(200, _delivery(retry ? 'ACCEPTED' : 'AVAILABLE')),
        );
      });
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
      expect(find.text('Current backend delivery status'), findsOneWidget);
      expect(find.text('Awaiting a delivery partner'), findsWidgets);
      refreshPending = true;
      await tester.ensureVisible(find.text('Refresh order and delivery'));
      await tester.tap(find.text('Refresh order and delivery'));
      await tester.pump();
      expect(find.text('Checking latest status…'), findsOneWidget);
      expect(find.text('Awaiting a delivery partner'), findsWidgets);
      final count = transport.requests.length;
      await tester.tap(find.text('Refresh order and delivery'));
      await tester.pump();
      expect(transport.requests.length, count);
      pending.complete(const ApiResponse(503, {'message': 'Unavailable'}));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Last loaded information is shown'),
        findsOneWidget,
      );
      expect(find.text('Awaiting a delivery partner'), findsWidgets);
      refreshPending = false;
      retry = true;
      await tester.ensureVisible(find.text('Retry refresh'));
      await tester.tap(find.text('Retry refresh'));
      await tester.pumpAndSettle();
      expect(find.text('Accepted'), findsWidgets);
      expect(
        find.textContaining('Last loaded information is shown'),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('terminal and unlinked timelines do not invent events', (
    tester,
  ) async {
    final transport = _Transport(
      (request) async => ApiResponse(
        200,
        request.uri.path == ApiRoutes.order('order-1')
            ? _order(
                status: 'DELIVERED',
                delivery: {'id': 'delivery-1', 'status': 'DELIVERED'},
              )
            : (_delivery('DELIVERED')..['deliveredAt'] = _stamp),
      ),
    );
    final repo = _repository(transport, _Auth());
    final delivered = (await repo.loadById('order-1'))!;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: DeliveryProgressCard(order: delivered, onRetry: () {}),
          ),
        ),
      ),
    );
    expect(find.text('Current backend delivery status'), findsOneWidget);
    expect(
      find.textContaining('Earlier stage inferred from current status'),
      findsWidgets,
    );
    expect(find.textContaining('Current backend status ·'), findsOneWidget);
    expect(find.textContaining('Confirmed by delivery record'), findsNothing);

    transport.handler = (request) async => ApiResponse(
      200,
      request.uri.path == ApiRoutes.order('order-1')
          ? _order(
              status: 'DELIVERED',
              delivery: {'id': 'delivery-1', 'status': 'DELIVERED'},
            )
          : (_delivery('DELIVERED')
              ..['acceptedAt'] = _stamp
              ..['pickedUpAt'] = _stamp
              ..['deliveredAt'] = _stamp),
    );
    final timestamped = (await repo.loadById('order-1'))!;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: DeliveryProgressCard(order: timestamped, onRetry: () {}),
          ),
        ),
      ),
    );
    expect(
      find.textContaining('Confirmed by delivery record'),
      findsNWidgets(2),
    );

    transport.handler = (request) async => ApiResponse(
      200,
      request.uri.path == ApiRoutes.order('order-1')
          ? _order(
              status: 'CANCELLED',
              delivery: {'id': 'delivery-1', 'status': 'CANCELLED'},
            )
          : _delivery('CANCELLED'),
    );
    final cancelled = (await repo.loadById('order-1'))!;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: DeliveryProgressCard(order: cancelled, onRetry: () {}),
          ),
        ),
      ),
    );
    expect(find.text('Cancelled'), findsOneWidget);
    expect(find.text('Not reported yet'), findsNothing);
    transport.handler = (_) async =>
        ApiResponse(200, _order(status: 'DELIVERED'));
    final unlinkedDelivered = (await repo.loadById('order-1'))!;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: DeliveryProgressCard(
              order: unlinkedDelivered,
              onRetry: () {},
            ),
          ),
        ),
      ),
    );
    expect(
      find.text(
        'This order is marked delivered, but no delivery record is linked.',
      ),
      findsOneWidget,
    );
    transport.handler = (_) async =>
        ApiResponse(200, _order(status: 'CANCELLED'));
    final unlinkedCancelled = (await repo.loadById('order-1'))!;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: DeliveryProgressCard(
              order: unlinkedCancelled,
              onRetry: () {},
            ),
          ),
        ),
      ),
    );
    expect(
      find.text('This order is cancelled. No delivery is linked.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  test('local mock repository still has no live delivery reads', () {
    final app = AppController();
    addTearDown(app.dispose);
    expect(app.liveOrders, isFalse);
    expect(app.liveDeliveryStatus, isFalse);
  });
}

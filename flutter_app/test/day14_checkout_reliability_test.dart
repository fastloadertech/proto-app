import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:proto/core/api/api_client.dart';
import 'package:proto/core/api/api_failure.dart';
import 'package:proto/core/api/api_routes.dart';
import 'package:proto/core/state/app_controller.dart';
import 'package:proto/features/auth/domain/auth_repository.dart';
import 'package:proto/features/catalog/data/local_catalog_repository.dart';
import 'package:proto/features/checkout/presentation/checkout_screen.dart';
import 'package:proto/features/orders/data/api_order_repository.dart';

final _product = LocalCatalogRepository.products.first;

class _Transport implements ApiTransport {
  _Transport(this.handler);
  final Future<ApiResponse> Function(ApiRequest) handler;
  final requests = <ApiRequest>[];

  @override
  Future<ApiResponse> send(ApiRequest request) {
    requests.add(request);
    return handler(request);
  }
}

class _Auth implements AuthRepository {
  @override
  CustomerSession? get currentSession => const CustomerSession(
    customerId: 'customer-1',
    phone: '+919876543210',
    name: 'Alex Rao',
    accessToken: 'test-token',
  );

  @override
  Future<CustomerSession> login(String phone, {String? code}) async =>
      currentSession!;
  @override
  Future<void> logout() async {}
  @override
  Future<CustomerSession?> restoreSession() async => currentSession;
}

AppController _app(_Transport transport) => AppController(
  orderRepository: ApiOrderRepository(
    client: ApiClient(transport: transport),
    auth: _Auth(),
    catalog: const LocalCatalogSource(),
  ),
);

Map<String, dynamic> _order() {
  final amount = _product.price.toStringAsFixed(2);
  return {
    'id': 'server-order-1',
    'reference': 'PR-1001',
    'status': 'PENDING',
    'subtotal': amount,
    'deliveryFee': '0.00',
    'total': amount,
    'currency': 'INR',
    'deliveryAddress': {
      'line1': '42, First Main Road',
      'line2': 'Indiranagar',
      'city': 'Bengaluru',
      'state': null,
      'postalCode': '560038',
      'recipientName': 'Alex Rao',
      'phone': '+919876543210',
    },
    'items': [
      {
        'id': 'item-1',
        'productId': _product.id,
        'productName': _product.name,
        'unitPrice': amount,
        'quantity': 1,
        'lineTotal': amount,
      },
    ],
    'createdAt': '2026-10-10T10:00:00.000Z',
    'updatedAt': '2026-10-10T10:00:00.000Z',
  };
}

Future<void> _submit(AppController app) => app.submitOrder(
  address: app.deliveryAddress,
  contact: app.contact,
  paymentMethod: app.paymentMethod,
);

void main() {
  test(
    'only one live POST can run at a time; success uses backend order',
    () async {
      final pending = Completer<ApiResponse>();
      final transport = _Transport((_) => pending.future);
      final app = _app(transport);
      addTearDown(app.dispose);
      app.add(_product);

      final first = app.submitOrder(
        address: app.deliveryAddress,
        contact: app.contact,
        paymentMethod: app.paymentMethod,
      );
      expect(app.orderSubmissionInProgress, isTrue);
      await expectLater(_submit(app), throwsStateError);
      expect(transport.requests, hasLength(1));

      pending.complete(ApiResponse(201, _order()));
      final created = await first;
      expect(created.id, 'server-order-1');
      expect(app.orders.single.id, created.id);
      expect(app.cartCount, 0);
      expect(app.orderSubmissionInProgress, isFalse);
      expect(app.orderSubmissionUncertain, isFalse);
      expect(transport.requests.single.uri.path, ApiRoutes.orders);
    },
  );

  test(
    'uncertain network result keeps bag and blocks a duplicate POST',
    () async {
      final transport = _Transport((_) async => throw Exception('timeout'));
      final app = _app(transport);
      addTearDown(app.dispose);
      app.add(_product);

      await expectLater(
        _submit(app),
        throwsA(
          isA<ApiFailure>().having(
            (e) => e.kind,
            'kind',
            ApiFailureKind.network,
          ),
        ),
      );
      expect(app.cartCount, 1);
      expect(app.orders, isEmpty);
      expect(app.orderSubmissionUncertain, isTrue);
      await expectLater(_submit(app), throwsStateError);
      expect(transport.requests, hasLength(1));
    },
  );

  test(
    'malformed success is uncertain; definite rejection remains retryable',
    () async {
      var response = const ApiResponse(409, {'message': 'Inventory changed.'});
      final transport = _Transport((_) async => response);
      final app = _app(transport);
      addTearDown(app.dispose);
      app.add(_product);

      await expectLater(_submit(app), throwsA(isA<ApiFailure>()));
      expect(app.orderSubmissionUncertain, isFalse);
      response = const ApiResponse(201, {'id': 'incomplete'});
      await expectLater(_submit(app), throwsA(isA<ApiFailure>()));
      expect(app.orderSubmissionUncertain, isTrue);
      expect(app.cartCount, 1);
      expect(transport.requests, hasLength(2));
    },
  );

  testWidgets('checkout directs uncertain submissions to order history', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final transport = _Transport((_) async => throw Exception('timeout'));
    final app = _app(transport);
    addTearDown(app.dispose);
    app.add(_product);
    await tester.pumpWidget(
      AppScope(
        controller: app,
        child: MaterialApp(
          home: const CheckoutScreen(),
          routes: {
            '/orders': (_) =>
                const Scaffold(body: Text('Order history opened')),
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Place order'));
    await tester.tap(find.text('Place order'));
    await tester.pumpAndSettle();

    expect(find.textContaining('could not confirm'), findsOneWidget);
    expect(find.text('Review your orders'), findsOneWidget);
    final button = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Place order'),
    );
    expect(button.onPressed, isNull);
    expect(app.cartCount, 1);
    expect(transport.requests, hasLength(1));
    await tester.ensureVisible(find.text('Review your orders'));
    await tester.tap(find.text('Review your orders'));
    await tester.pumpAndSettle();
    expect(find.text('Order history opened'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(
      AppScope(
        controller: app,
        child: const MaterialApp(home: CheckoutScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.textContaining('previous order may have been placed'),
      findsOneWidget,
    );
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Place order'),
          )
          .onPressed,
      isNull,
    );
    expect(tester.takeException(), isNull);
  });
}

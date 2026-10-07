import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:proto/core/formatters/order_date.dart';
import 'package:proto/core/state/app_controller.dart';
import 'package:proto/core/theme/proto_theme.dart';
import 'package:proto/features/catalog/data/local_catalog_repository.dart';
import 'package:proto/features/checkout/presentation/checkout_screen.dart';
import 'package:proto/features/checkout/presentation/delivery_address_screen.dart';
import 'package:proto/features/orders/data/local_order_repository.dart';
import 'package:proto/features/orders/domain/order.dart';
import 'package:proto/features/orders/presentation/order_status_screen.dart';
import 'package:proto/features/orders/presentation/orders_screen.dart';
import 'package:proto/features/profile/presentation/profile_screen.dart';

DeliveryAddress address(String street, String label, {String id = ''}) =>
    DeliveryAddress(
      line1: street,
      area: 'Indiranagar',
      city: 'Bengaluru',
      postalCode: '560038',
      label: label,
      id: id,
    );

Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> mount(
  WidgetTester tester,
  AppController app,
  Widget home, {
  Size size = const Size(390, 844),
  double textScale = 1,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(app.dispose);
  await tester.pumpWidget(
    AppScope(
      controller: app,
      child: MaterialApp(
        theme: ProtoTheme.theme,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: home,
        routes: {
          '/addresses': (_) => const DeliveryAddressScreen(),
          '/shop': (_) => const Scaffold(body: Text('Shop')),
        },
      ),
    ),
  );
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

  test('fourth address and repeated labels retain stable identity', () {
    final app = AppController();
    addTearDown(app.dispose);
    app.saveDeliveryAddress(address('12, Work Street', 'Work'));
    app.saveDeliveryAddress(address('14, Gym Road', 'Other'));
    app.saveDeliveryAddress(address('16, Park Lane', 'Other'));

    final saved = app.savedAddresses;
    expect(saved, hasLength(4));
    expect(saved.map((entry) => entry.id).toSet(), hasLength(4));
    expect(saved.where((entry) => entry.label == 'Other'), hasLength(2));
    final firstOther = saved[2];
    final secondOther = saved[3];
    app.selectSavedAddress(firstOther.id);
    expect(app.deliveryAddress.line1, '14, Gym Road');
    app.saveDeliveryAddress(
      address('18, Updated Lane', 'Home', id: secondOther.id),
    );
    expect(app.savedAddresses, hasLength(4));
    expect(app.savedAddresses[2].line1, '14, Gym Road');
    expect(app.savedAddresses[3].id, secondOther.id);
    expect(app.savedAddresses[3].label, 'Home');
    expect(() => app.selectSavedAddress('missing'), throwsArgumentError);

    app.selectSavedAddress(firstOther.id);
    app.add(LocalCatalogRepository.products.first);
    final placed = app.placeOrder(
      address: address('20, Delivery Lane', 'Other', id: firstOther.id),
      contact: app.contact,
      paymentMethod: PaymentMethod.cashOnDelivery,
    );
    expect(placed.address.id, firstOther.id);
    expect(placed.address.line1, '20, Delivery Lane');
    expect(app.savedAddresses, hasLength(4));
    expect(app.savedAddresses[2].line1, '20, Delivery Lane');
    expect(app.savedAddresses[3].id, secondOther.id);
    expect(app.cartCount, 0);
  });

  testWidgets('checkout can add and select a fourth saved address', (
    tester,
  ) async {
    final app = AppController()
      ..add(LocalCatalogRepository.products.first)
      ..saveDeliveryAddress(address('12, Work Street', 'Work'))
      ..saveDeliveryAddress(address('14, Gym Road', 'Other'));
    final previousOther = app.savedAddresses.last;
    await mount(tester, app, const CheckoutScreen());

    await tapVisible(tester, find.text('Choose saved address'));
    await tapVisible(tester, find.text('Add another address'));
    await tester.enterText(
      find.byKey(const ValueKey('saved-street-address')),
      '16, Park Lane',
    );
    await tester.enterText(
      find.byKey(const ValueKey('saved-area')),
      'Indiranagar',
    );
    await tester.enterText(
      find.byKey(const ValueKey('saved-city')),
      'Bengaluru',
    );
    await tester.enterText(
      find.byKey(const ValueKey('saved-pin-code')),
      '560038',
    );
    await tapVisible(tester, find.text('Save and use address'));
    expect(app.savedAddresses, hasLength(4));
    expect(app.deliveryAddress.line1, '16, Park Lane');
    expect(app.savedAddresses[2].id, previousOther.id);
    expect(app.savedAddresses[2].line1, previousOther.line1);

    await tapVisible(tester, find.text('Choose saved address'));
    final firstOtherCard = find.byKey(
      ValueKey('saved-address-${previousOther.id}'),
    );
    final semantics = tester.ensureSemantics();
    expect(
      find.bySemanticsLabel('Use Other address at 14, Gym Road'),
      findsOneWidget,
    );
    semantics.dispose();
    await tapVisible(
      tester,
      find.descendant(of: firstOtherCard, matching: find.text('Use Other')),
    );
    expect(app.deliveryAddress.id, previousOther.id);
    expect(app.deliveryAddress.line1, '14, Gym Road');
    expect(find.text('Deliver to · Other'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('profile opens saved addresses at enlarged mobile text scale', (
    tester,
  ) async {
    final app = AppController();
    await mount(
      tester,
      app,
      ProfileScreen(onBrowse: () {}, onSignIn: () {}),
      size: const Size(320, 640),
      textScale: 2,
    );
    expect(tester.takeException(), isNull);
    await tapVisible(tester, find.text('Saved addresses'));
    expect(find.byType(DeliveryAddressScreen), findsOneWidget);
    expect(find.text('Use Home'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('history and order details show the same placed date and time', (
    tester,
  ) async {
    final repository = LocalOrderRepository(
      clock: () => DateTime(2026, 10, 2, 14, 5),
    );
    final app = AppController(orderRepository: repository);
    final product = LocalCatalogRepository.products.first;
    final order = repository.create(
      items: [
        OrderItem(
          product: product,
          flavor: product.flavors.first,
          quantity: 2,
          unitPrice: product.price,
        ),
      ],
      address: app.deliveryAddress,
      contact: app.contact,
      paymentMethod: PaymentMethod.cashOnDelivery,
      deliveryFee: 35,
    );
    await mount(tester, app, const OrdersScreen());
    final timestamp = formatOrderDate(order.createdAt);
    expect(find.text(timestamp), findsOneWidget);
    await tapVisible(tester, find.text(order.id));
    expect(find.byType(OrderStatusScreen), findsOneWidget);
    expect(find.text('Placed $timestamp'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

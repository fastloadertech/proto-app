import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:proto/app/main_shell.dart';
import 'package:proto/core/formatters/currency.dart';
import 'package:proto/core/state/app_controller.dart';
import 'package:proto/core/theme/proto_theme.dart';
import 'package:proto/features/bag/presentation/bag_screen.dart';
import 'package:proto/features/catalog/data/local_catalog_repository.dart';
import 'package:proto/features/catalog/presentation/product_detail_screen.dart';
import 'package:proto/features/checkout/presentation/checkout_screen.dart';
import 'package:proto/features/orders/domain/order.dart';
import 'package:proto/features/orders/presentation/order_confirmation_screen.dart';
import 'package:proto/features/orders/presentation/order_status_screen.dart';
import 'package:proto/features/orders/presentation/orders_screen.dart';

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();
  if (finder.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      finder,
      180,
      scrollable: find.byType(Scrollable).first,
    );
  }
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
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

  testWidgets('larger-text mobile purchase remains in order history', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 640);
    tester.binding.platformDispatcher.textScaleFactorTestValue = 1.75;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(
      tester.binding.platformDispatcher.clearTextScaleFactorTestValue,
    );

    final app = AppController();
    addTearDown(app.dispose);
    final product = LocalCatalogRepository.products.firstWhere(
      (item) => item.id == 'whey-isolate',
    );
    expect(product.isAvailable, isTrue);

    await tester.pumpWidget(
      AppScope(
        controller: app,
        child: MaterialApp(
          theme: ProtoTheme.theme,
          home: ProductDetailScreen(product: product),
          routes: {
            '/bag': (context) => BagScreen(
              standalone: true,
              onBrowse: () => Navigator.of(context).pop(),
            ),
            '/checkout': (_) => const CheckoutScreen(),
            '/shop': (_) => const MainShell(),
            '/orders': (_) => const OrdersScreen(),
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await _tapVisible(tester, find.byTooltip('Increase quantity'));
    await _tapVisible(tester, find.text('Add to bag'));
    expect(app.quantityFor(product.id), 2);
    await _tapVisible(tester, find.text('View bag'));
    expect(find.byType(BagScreen), findsOneWidget);
    expect(tester.takeException(), isNull);

    await _tapVisible(tester, find.byTooltip('Add another ${product.name}'));
    expect(app.quantityFor(product.id), 3);
    await _tapVisible(tester, find.byTooltip('Remove ${product.name}'));
    expect(app.quantityFor(product.id), 2);
    expect(app.subtotal, product.price * 2);
    final expectedTotal = app.total;
    await _tapVisible(tester, find.text('Checkout'));
    expect(find.byType(CheckoutScreen), findsOneWidget);
    expect(find.text(formatPrice(expectedTotal)), findsWidgets);
    expect(tester.takeException(), isNull);

    await _tapVisible(tester, find.text('Card demo'));
    await _tapVisible(tester, find.text('Place order'));
    expect(find.byType(OrderConfirmationScreen), findsOneWidget);
    expect(app.cartCount, 0);
    expect(app.orders, hasLength(1));
    final order = app.orders.single;
    expect(order.items.single.quantity, 2);
    expect(order.total, expectedTotal);
    expect(order.address, app.deliveryAddress);
    expect(order.paymentMethod, PaymentMethod.mockCard);
    expect(find.text(order.id), findsOneWidget);
    expect(tester.takeException(), isNull);

    await _tapVisible(tester, find.text('Continue shopping'));
    expect(find.byType(MainShell), findsOneWidget);
    await _tapVisible(tester, find.text('You').last);
    await _tapVisible(tester, find.text('Your orders'));
    expect(find.byType(OrdersScreen), findsOneWidget);
    await _tapVisible(tester, find.text(order.id));
    expect(find.byType(OrderStatusScreen), findsOneWidget);
    expect(find.text(product.name), findsOneWidget);
    expect(find.text(order.address.formatted), findsOneWidget);
    expect(app.orderById(order.id)?.status, OrderStatus.orderPlaced);
    expect(tester.takeException(), isNull);
  });
}

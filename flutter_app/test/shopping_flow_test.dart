import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:proto/app/main_shell.dart';
import 'package:proto/app/proto_app.dart';
import 'package:proto/core/formatters/currency.dart';
import 'package:proto/core/state/app_controller.dart';
import 'package:proto/core/theme/proto_theme.dart';
import 'package:proto/core/widgets/product_card.dart';
import 'package:proto/core/widgets/proto_button.dart';
import 'package:proto/features/bag/presentation/bag_screen.dart';
import 'package:proto/features/catalog/data/local_catalog_repository.dart';
import 'package:proto/features/catalog/presentation/product_detail_screen.dart';
import 'package:proto/features/catalog/presentation/product_listing_screen.dart';
import 'package:proto/features/checkout/presentation/checkout_screen.dart';
import 'package:proto/features/orders/domain/order.dart';
import 'package:proto/features/orders/presentation/order_confirmation_screen.dart';
import 'package:proto/features/orders/presentation/order_status_screen.dart';
import 'package:proto/features/orders/presentation/orders_screen.dart';

void _viewport(WidgetTester tester, Size size) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();
  if (finder.evaluate().isEmpty) {
    // Sliver children outside short landscape viewports are built on scroll.
    await tester.scrollUntilVisible(
      finder,
      200,
      scrollable: find.byType(Scrollable).first,
    );
  }
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _guest(WidgetTester tester) async {
  await tester.pumpWidget(const ProtoApp());
  await tester.pump(const Duration(milliseconds: 1400));
  await tester.pumpAndSettle();
  await _tap(tester, find.text('Explore as guest'));
}

Future<void> _session(
  WidgetTester tester,
  AppController app,
  Widget screen,
) async {
  addTearDown(app.dispose);
  await tester.pumpWidget(
    AppScope(
      controller: app,
      child: MaterialApp(
        theme: ProtoTheme.theme,
        home: screen,
        routes: {
          '/shop': (_) => const MainShell(),
          '/bag': (context) => BagScreen(
            standalone: true,
            onBrowse: () => Navigator.of(
              context,
            ).pushNamedAndRemoveUntil('/shop', (_) => false),
          ),
          '/checkout': (_) => const CheckoutScreen(),
          '/orders': (_) => const OrdersScreen(),
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

  testWidgets(
    'category chips filter results and quick controls update the bag',
    (tester) async {
      _viewport(tester, const Size(390, 844));
      final app = AppController();
      await _session(
        tester,
        app,
        const ProductListingScreen(categoryId: 'protein'),
      );
      expect(
        tester
            .widgetList<ProductCard>(find.byType(ProductCard))
            .map((card) => card.product.categoryId),
        everyElement('protein'),
      );

      await _tap(tester, find.text('Hydration').last);
      final expected = LocalCatalogRepository.byCategory('hydration');
      expect(find.text('${expected.length} essentials'), findsOneWidget);
      final cards = tester.widgetList<ProductCard>(find.byType(ProductCard));
      expect(cards, isNotEmpty);
      expect(
        cards.map((card) => card.product.categoryId),
        everyElement('hydration'),
      );
      final first = find.byType(ProductCard).first;
      final product = tester.widget<ProductCard>(first).product;
      await _tap(
        tester,
        find.descendant(of: first, matching: find.text('ADD')),
      );
      expect(app.quantityFor(product.id), 1);
      await _tap(tester, find.byTooltip('Add one ${product.name}'));
      expect(app.quantityFor(product.id), 2);
      await _tap(tester, find.byTooltip('Remove one ${product.name}'));
      expect(app.quantityFor(product.id), 1);

      await _tap(tester, find.text('All products'));
      expect(
        find.text('${LocalCatalogRepository.products.length} essentials'),
        findsOneWidget,
      );
      expect(app.cartCount, 1);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('complete customer journey creates and tracks one local order', (
    tester,
  ) async {
    _viewport(tester, const Size(390, 844));
    await _guest(tester);
    await _tap(tester, find.text('Categories').last);
    await _tap(tester, find.text('Protein').first);
    final firstCard = find.byType(ProductCard).first;
    final product = tester.widget<ProductCard>(firstCard).product;
    await _tap(
      tester,
      find.descendant(of: firstCard, matching: find.text(product.name)),
    );
    expect(find.byType(ProductDetailScreen), findsOneWidget);
    final app = AppScope.of(tester.element(find.byType(ProductDetailScreen)));
    final flavor = product.flavors.last;
    await _tap(tester, find.text(flavor));
    await _tap(tester, find.byTooltip('Increase quantity'));
    await _tap(tester, find.byTooltip('Increase quantity'));
    await _tap(tester, find.byTooltip('Decrease quantity'));
    expect(app.cartCount, 0);
    await _tap(tester, find.text('Add to bag'));
    expect(app.quantityFor(product.id, flavor: flavor), 2);
    expect(find.text('2 in bag'), findsOneWidget);
    await _tap(tester, find.text('View bag'));
    expect(find.byType(BagScreen), findsOneWidget);
    await _tap(tester, find.byTooltip('Add another ${product.name}'));
    expect(app.cartCount, 3);
    await _tap(tester, find.byTooltip('Remove ${product.name}'));
    expect(app.cartCount, 2);
    final total = app.total;
    await _tap(tester, find.text('Checkout'));
    expect(find.byType(CheckoutScreen), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Full name'),
      'Sam Lee',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Mobile number'),
      '9988776655',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Street address'),
      '7, Training Avenue',
    );
    await _tap(tester, find.text('UPI demo'));
    await tester.ensureVisible(find.text('Place order'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Place order'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Placing order…'), findsOneWidget);
    expect(app.orders, isEmpty);
    final placingButton = tester.widget<ProtoButton>(
      find.byWidgetPredicate(
        (widget) => widget is ProtoButton && widget.label == 'Placing order…',
      ),
    );
    expect(placingButton.loading, isTrue);
    expect(placingButton.onPressed, isNull);
    await tester.tap(find.text('Placing order…'));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();
    expect(find.byType(OrderConfirmationScreen), findsOneWidget);
    expect(app.orders, hasLength(1));
    expect(app.cartCount, 0);
    final order = app.orders.single;
    expect(order.total, total);
    expect(order.items.single.quantity, 2);
    expect(order.items.single.flavor, flavor);
    expect(order.contact.name, 'Sam Lee');
    expect(order.contact.phone, '9988776655');
    expect(order.address.line1, '7, Training Avenue');
    expect(order.paymentMethod, PaymentMethod.mockUpi);
    expect(find.text(order.id), findsOneWidget);
    expect(find.text('Demo ETA · about 12 min'), findsOneWidget);
    expect(find.text(order.address.formatted), findsOneWidget);
    expect(find.text(formatPrice(total)), findsWidgets);

    await _tap(tester, find.text('Track order'));
    expect(find.byType(OrderStatusScreen), findsOneWidget);
    for (final next in OrderStatus.values.skip(1)) {
      await _tap(tester, find.text('Advance demo status'));
      expect(app.orderById(order.id)!.status, next);
      expect(find.text(next.label), findsNWidgets(2));
      expect(find.text('Current demo stage'), findsOneWidget);
    }
    final statusButton = tester.widget<ProtoButton>(
      find.byWidgetPredicate(
        (widget) =>
            widget is ProtoButton && widget.label == 'Advance demo status',
      ),
    );
    expect(statusButton.onPressed, isNull);
    await _tap(tester, find.text('Continue shopping'));
    expect(find.text('Fuel your next level.'), findsOneWidget);
    await _tap(tester, find.text('You').last);
    await _tap(tester, find.text('Your orders'));
    expect(find.byType(OrdersScreen), findsOneWidget);
    expect(find.text(order.id), findsOneWidget);
    expect(find.text('Delivered'), findsOneWidget);
    await _tap(tester, find.text(order.id));
    expect(find.byType(OrderStatusScreen), findsOneWidget);
    expect(app.orders, hasLength(1));
    expect(app.orderById(order.id)!.status, OrderStatus.delivered);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'checkout validates contact and address before creating an order',
    (tester) async {
      _viewport(tester, const Size(390, 844));
      final app = AppController()..add(LocalCatalogRepository.products.first);
      await _session(tester, app, const CheckoutScreen());
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Full name'),
        '',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Mobile number'),
        '123',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'PIN code'),
        '000000',
      );
      await _tap(tester, find.text('Place order'));
      expect(find.text('Enter your full name.'), findsOneWidget);
      expect(find.text('Enter a 10-digit mobile number.'), findsOneWidget);
      expect(find.text('Enter a valid 6-digit PIN code.'), findsOneWidget);
      expect(
        find.text('Check the highlighted details to continue.'),
        findsOneWidget,
      );
      expect(app.orders, isEmpty);
      expect(app.cartCount, 1);
      expect(find.byType(CheckoutScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'checkout cancellation preserves the bag and full removal empties it',
    (tester) async {
      _viewport(tester, const Size(390, 844));
      final product = LocalCatalogRepository.products.first;
      final app = AppController()..add(product, quantity: 3);
      await _session(tester, app, const MainShell());
      await _tap(tester, find.text('Bag').last);
      await _tap(tester, find.text('Checkout'));
      await _tap(tester, find.byTooltip('Back'));
      expect(app.cartCount, 3);
      expect(app.orders, isEmpty);
      expect(find.byType(BagScreen), findsOneWidget);
      await _tap(
        tester,
        find.byTooltip('Remove item ${product.name} ${product.flavors.first}'),
      );
      expect(app.cartCount, 0);
      expect(find.text('Make room for good fuel.'), findsOneWidget);
      expect(find.text('Checkout'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('empty checkout and unknown orders show recoverable states', (
    tester,
  ) async {
    _viewport(tester, const Size(320, 640));
    final app = AppController();
    await _session(tester, app, const CheckoutScreen());
    expect(find.text('Place order'), findsNothing);
    expect(find.byType(TextFormField), findsNothing);
    expect(app.orders, isEmpty);
    await tester.pumpWidget(const SizedBox());
    await _session(tester, AppController(), const OrdersScreen());
    expect(find.text('Your orders'), findsOneWidget);
    expect(find.text('Explore the shop'), findsOneWidget);
    await _tap(tester, find.text('Explore the shop'));
    expect(find.byType(MainShell), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await _session(
      tester,
      AppController(),
      const OrderStatusScreen(orderId: 'unknown'),
    );
    expect(find.text('Order unavailable'), findsOneWidget);
    expect(find.text('Advance demo status'), findsNothing);
    await _tap(tester, find.text('Return to shop'));
    expect(find.byType(MainShell), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final size in [
    const Size(320, 640),
    const Size(640, 320),
    const Size(1440, 900),
  ]) {
    testWidgets('bag, checkout, confirmation and status fit $size', (
      tester,
    ) async {
      _viewport(tester, size);
      final app = AppController()..add(LocalCatalogRepository.products.first);
      await _session(tester, app, const MainShell());
      await _tap(tester, find.text('Bag').last);
      expect(tester.takeException(), isNull);
      await _tap(tester, find.text('Checkout'));
      expect(tester.takeException(), isNull);
      await _tap(tester, find.text('Card demo'));
      await _tap(tester, find.text('Place order'));
      expect(find.byType(OrderConfirmationScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
      await _tap(tester, find.text('Track order'));
      expect(find.byType(OrderStatusScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
      await _tap(tester, find.text('Advance demo status'));
      expect(app.orders.single.status, OrderStatus.confirmed);
      expect(tester.takeException(), isNull);
    });
  }
}

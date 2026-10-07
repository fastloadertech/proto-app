import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:proto/app/proto_app.dart';
import 'package:proto/core/state/app_controller.dart';
import 'package:proto/core/widgets/product_card.dart';
import 'package:proto/features/bag/presentation/bag_screen.dart';
import 'package:proto/features/catalog/presentation/product_detail_screen.dart';
import 'package:proto/features/checkout/presentation/checkout_screen.dart';
import 'package:proto/features/checkout/presentation/delivery_address_screen.dart';

Future<void> _tap(WidgetTester tester, Finder finder) async {
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

  testWidgets('narrow enlarged-text shopping and address flow stays usable', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 640);
    tester.binding.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(
      tester.binding.platformDispatcher.clearTextScaleFactorTestValue,
    );

    await tester.pumpWidget(const ProtoApp());
    await tester.pump(const Duration(milliseconds: 1400));
    await tester.pumpAndSettle();
    await _tap(tester, find.text('Explore as guest'));
    expect(tester.takeException(), isNull);

    await _tap(tester, find.text('Search protein, creatine, snacks…'));
    await tester.enterText(find.byType(TextField), 'whey');
    await tester.pumpAndSettle();
    final isolateCard = find.byWidgetPredicate(
      (widget) => widget is ProductCard && widget.product.id == 'whey-isolate',
    );
    await _tap(
      tester,
      find.descendant(of: isolateCard, matching: find.text('Whey Isolate')),
    );
    expect(find.byType(ProductDetailScreen), findsOneWidget);
    expect(tester.takeException(), isNull);

    final app = AppScope.of(tester.element(find.byType(ProductDetailScreen)));
    await _tap(tester, find.byTooltip('Increase quantity'));
    await _tap(tester, find.text('Add to bag'));
    expect(app.quantityFor('whey-isolate'), 2);
    await _tap(tester, find.text('View bag'));
    expect(find.byType(BagScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
    expect(
      tester.getSize(find.byTooltip('Remove Whey Isolate')).shortestSide,
      greaterThanOrEqualTo(44),
    );
    expect(
      tester.getSize(find.byTooltip('Add another Whey Isolate')).shortestSide,
      greaterThanOrEqualTo(44),
    );

    await _tap(tester, find.byTooltip('Remove Whey Isolate'));
    expect(app.quantityFor('whey-isolate'), 1);
    await _tap(tester, find.text('Checkout'));
    expect(find.byType(CheckoutScreen), findsOneWidget);
    expect(tester.takeException(), isNull);

    await _tap(tester, find.text('Choose saved address'));
    expect(find.byType(DeliveryAddressScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
    await _tap(tester, find.text('Use Home'));
    expect(find.byType(CheckoutScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

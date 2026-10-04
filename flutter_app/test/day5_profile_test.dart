import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:proto/app/proto_app.dart';
import 'package:proto/core/state/app_controller.dart';
import 'package:proto/core/theme/proto_theme.dart';
import 'package:proto/features/checkout/presentation/delivery_address_screen.dart';
import 'package:proto/features/orders/presentation/orders_screen.dart';
import 'package:proto/features/profile/presentation/profile_screen.dart';
import 'package:proto/features/profile/presentation/profile_settings_screen.dart';

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
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

  testWidgets('profile shortcuts, local settings, About and demo logout', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const ProtoApp());
    await tester.pump(const Duration(milliseconds: 1400));
    await tester.pumpAndSettle();
    await _tapVisible(tester, find.text('Explore as guest'));
    await _tapVisible(tester, find.text('You').last);
    expect(find.byType(ProfileScreen), findsOneWidget);
    expect(find.text('Alex Rao'), findsOneWidget);
    expect(find.textContaining('9876543210'), findsOneWidget);

    await _tapVisible(tester, find.text('Your orders'));
    expect(find.byType(OrdersScreen), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    await _tapVisible(tester, find.text('Saved addresses'));
    expect(find.byType(DeliveryAddressScreen), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    await _tapVisible(tester, find.text('Settings'));
    expect(find.byType(ProfileSettingsScreen), findsOneWidget);
    final orderSetting = find.widgetWithText(SwitchListTile, 'Order updates');
    expect(tester.widget<SwitchListTile>(orderSetting).value, isTrue);
    await _tapVisible(tester, orderSetting);
    expect(tester.widget<SwitchListTile>(orderSetting).value, isFalse);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await _tapVisible(tester, find.text('Settings'));
    expect(tester.widget<SwitchListTile>(orderSetting).value, isFalse);
    await tester.pageBack();
    await tester.pumpAndSettle();

    await _tapVisible(tester, find.text('About Proto'));
    expect(find.textContaining('Proto brings protein'), findsOneWidget);
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    await _tapVisible(tester, find.text('Log out'));
    expect(find.text('Leave the demo?'), findsOneWidget);
    await tester.tap(find.text('Stay here'));
    await tester.pumpAndSettle();
    expect(find.byType(ProfileScreen), findsOneWidget);
    await _tapVisible(tester, find.text('Log out'));
    await tester.tap(find.text('Log out').last);
    await tester.pumpAndSettle();
    expect(find.text('Explore as guest'), findsOneWidget);
    expect(find.byType(ProfileScreen), findsNothing);
    await _tapVisible(tester, find.text('Explore as guest'));
    expect(find.text('Fuel your next level.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('profile and settings fit narrow mobile with enlarged text', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 640);
    tester.binding.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(
      tester.binding.platformDispatcher.clearTextScaleFactorTestValue,
    );
    final app = AppController();
    addTearDown(app.dispose);
    await tester.pumpWidget(
      AppScope(
        controller: app,
        child: MaterialApp(
          theme: ProtoTheme.theme,
          home: Scaffold(
            body: ProfileScreen(onBrowse: () {}, onSignIn: () {}),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    await _tapVisible(tester, find.text('Settings'));
    expect(find.byType(ProfileSettingsScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
    await _tapVisible(tester, find.text('Product offers'));
    expect(tester.takeException(), isNull);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await _tapVisible(tester, find.text('About Proto'));
    expect(tester.takeException(), isNull);
  });
}

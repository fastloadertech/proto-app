import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:proto/app/main_shell.dart';
import 'package:proto/core/theme/proto_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await (FontLoader(
      'Inter',
    )..addFont(rootBundle.load('assets/fonts/Inter.ttf'))).load();
  });

  for (final (size, textScale) in [
    (const Size(320, 640), 3.0),
    (const Size(390, 844), 1.0),
    (const Size(1440, 900), 1.0),
  ]) {
    testWidgets('bottom navigation fits at $size with ${textScale}x text', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      tester.binding.platformDispatcher.textScaleFactorTestValue = textScale;
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(
        tester.binding.platformDispatcher.clearTextScaleFactorTestValue,
      );

      int? selectedIndex;
      await tester.pumpWidget(
        MaterialApp(
          theme: ProtoTheme.theme,
          home: Scaffold(
            bottomNavigationBar: MainShellNavigationBar(
              selectedIndex: 0,
              cartCount: 0,
              onSelect: (index) => selectedIndex = index,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      final nav = tester.getRect(find.byType(MainShellNavigationBar));
      final categoryLabel = tester.getRect(find.text('Categories'));
      expect(categoryLabel.top, greaterThanOrEqualTo(nav.top));
      expect(categoryLabel.bottom, lessThanOrEqualTo(nav.bottom));
      expect(find.text('Shop'), findsOneWidget);
      expect(find.text('Bag'), findsOneWidget);
      expect(find.text('You'), findsOneWidget);

      await tester.tap(find.text('Categories'));
      expect(selectedIndex, 1);
    });
  }
}

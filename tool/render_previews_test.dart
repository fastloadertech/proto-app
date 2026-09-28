// Run explicitly: flutter test tool/render_previews_test.dart
// Writes real Flutter engine renders for visual review; not part of the suite.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:proto/app/proto_app.dart';
import 'package:proto/core/widgets/product_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final loader = FontLoader('Inter')
      ..addFont(rootBundle.load('assets/fonts/Inter.ttf'));
    await loader.load();
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
  });

  testWidgets('render customer screens for visual review', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final key = GlobalKey();

    Future<void> capture(String name) async {
      await tester.pumpAndSettle();
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final frame = await boundary.toImage(pixelRatio: 2);
        final bytes = await frame.toByteData(format: ui.ImageByteFormat.png);
        final directory = Directory('.artifacts/previews')
          ..createSync(recursive: true);
        await File(
          '${directory.path}/$name.png',
        ).writeAsBytes(bytes!.buffer.asUint8List());
        frame.dispose();
      });
    }

    await tester.pumpWidget(RepaintBoundary(key: key, child: const ProtoApp()));
    await tester.pump(const Duration(milliseconds: 500));
    // Splash is animated and timed; its layout is covered by navigation tests.
    await tester.pump(const Duration(milliseconds: 1000));
    await capture('login');
    await tester.ensureVisible(find.text('Explore as guest'));
    await tester.tap(find.text('Explore as guest'));
    await capture('home');
    await tester.tap(find.text('Categories'));
    await capture('categories');
    await tester.tap(find.text('Protein').first);
    await capture('products');
    final card = find.byType(ProductCard).first;
    final product = tester.widget<ProductCard>(card).product;
    final title = find.descendant(of: card, matching: find.text(product.name));
    await tester.ensureVisible(title);
    await tester.pumpAndSettle();
    await tester.tap(title);
    await capture('details');
    await tester.tap(find.text('Add to bag'));
    await tester.ensureVisible(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bag'));
    await capture('bag');
    tester.view.physicalSize = const Size(1440, 900);
    await tester.tap(find.text('Shop'));
    await capture('home-desktop');
  });
}

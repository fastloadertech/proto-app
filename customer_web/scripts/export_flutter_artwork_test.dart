// Run from D:/proto-app/flutter_app with:
// flutter test ../customer_web/scripts/export_flutter_artwork_test.dart
//
// Exports the existing Flutter ProductArtwork painter. No approximated web art.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:proto/core/widgets/product_artwork.dart';
import 'package:proto/features/catalog/data/local_catalog_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    final font = FontLoader('Inter')
      ..addFont(rootBundle.load('assets/fonts/Inter.ttf'));
    await font.load();
  });

  testWidgets('export transparent Proto packaging images', (tester) async {
    final output = Directory('../customer_web/public/images').absolute;
    if (!output.existsSync()) {
      throw StateError('Run this test from the Flutter app directory.');
    }

    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 360);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    for (final product in LocalCatalogRepository.products) {
      final boundaryKey = GlobalKey();
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: RepaintBoundary(
              key: boundaryKey,
              child: ProductArtwork(
                product: product,
                size: 300,
                showGlow: false,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      final boundary =
          boundaryKey.currentContext!.findRenderObject()!
              as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: 3);
        try {
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          final file = File('${output.path}/proto-${product.id}.png');
          await file.writeAsBytes(bytes!.buffer.asUint8List());
          print('Exported ${file.path} (${image.width}x${image.height})');
        } finally {
          image.dispose();
        }
      });
    }
  });
}

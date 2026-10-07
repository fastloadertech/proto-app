import 'package:flutter_test/flutter_test.dart';
import 'package:proto/core/state/app_controller.dart';
import 'package:proto/features/catalog/data/local_catalog_repository.dart';

void main() {
  late AppController controller;

  setUp(() => controller = AppController());
  tearDown(() => controller.dispose());

  test(
    'bag quantities, subtotal, and savings stay consistent after removals',
    () {
      final whey = LocalCatalogRepository.products.first;
      final secondProduct = LocalCatalogRepository.products[1];

      expect(controller.cartCount, 0);
      expect(controller.cartProducts, isEmpty);

      controller.add(whey);
      controller.add(whey);
      controller.add(secondProduct);

      expect(controller.quantityFor(whey.id), 2);
      expect(controller.cartCount, 3);
      expect(controller.cartProducts, containsAll([whey, secondProduct]));
      expect(controller.subtotal, whey.price * 2 + secondProduct.price);
      expect(
        controller.savings,
        (whey.originalPrice - whey.price) * 2 +
            secondProduct.originalPrice -
            secondProduct.price,
      );

      controller.remove(whey);
      expect(controller.quantityFor(whey.id), 1);
      expect(controller.cartCount, 2);
      controller.remove(whey);
      expect(controller.quantityFor(whey.id), 0);
      expect(controller.cartProducts, [secondProduct]);
      controller.remove(secondProduct);
      controller.remove(secondProduct);

      expect(controller.cartCount, 0);
      expect(controller.cartProducts, isEmpty);
      expect(controller.subtotal, 0);
      expect(controller.savings, 0);
    },
  );

  test('saving a product toggles without changing the bag', () {
    final product = LocalCatalogRepository.products.first;
    controller.toggleSaved(product);

    expect(controller.isSaved(product.id), isTrue);
    expect(controller.savedProductIds, {product.id});
    expect(controller.cartCount, 0);
    expect(
      () => controller.savedProductIds.add('external-change'),
      throwsUnsupportedError,
    );

    controller.toggleSaved(product);
    expect(controller.isSaved(product.id), isFalse);
    expect(controller.savedProductIds, isEmpty);
  });

  test('different flavors keep independent quantities in the bag', () {
    final product = LocalCatalogRepository.products.first;
    final firstFlavor = product.flavors.first;
    final secondFlavor = product.flavors.last;
    expect(firstFlavor, isNot(secondFlavor));
    controller.add(product, flavor: firstFlavor);
    controller.add(product, flavor: secondFlavor);
    controller.add(product, flavor: secondFlavor);
    expect(controller.bagLines, hasLength(2));
    expect(controller.quantityFor(product.id), 3);
    expect(controller.quantityFor(product.id, flavor: firstFlavor), 1);
    expect(controller.quantityFor(product.id, flavor: secondFlavor), 2);
    expect(controller.subtotal, product.price * 3);
    controller.remove(product, flavor: firstFlavor);
    expect(controller.bagLines, hasLength(1));
    expect(controller.bagLines.single.flavor, secondFlavor);
    expect(controller.quantityFor(product.id, flavor: secondFlavor), 2);
  });

  test('a selected delivery location is available to all listeners', () {
    var notifications = 0;
    controller.addListener(() => notifications++);

    controller.setLocation('Koramangala, Bengaluru');

    expect(controller.location, 'Koramangala, Bengaluru');
    expect(notifications, 1);
  });
}

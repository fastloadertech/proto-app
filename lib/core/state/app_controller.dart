import 'dart:collection';

import 'package:flutter/material.dart';

import '../../features/catalog/domain/product.dart';
import '../../features/catalog/data/local_catalog_repository.dart';

/// Day 1 session state. Data is local; nothing is persisted or sent to a server.
class AppController extends ChangeNotifier {
  final Map<(String, String?), BagLine> _bag = {};
  final Set<String> _savedIds = {};
  String _location = 'Indiranagar, Bengaluru';

  String get location => _location;
  int get cartCount =>
      _bag.values.fold(0, (total, line) => total + line.quantity);
  List<BagLine> get bagLines => List.unmodifiable(_bag.values);
  Set<String> get savedProductIds => UnmodifiableSetView(_savedIds);
  List<Product> get cartProducts => LocalCatalogRepository.products
      .where((product) => quantityFor(product.id) > 0)
      .toList(growable: false);
  double get subtotal => cartProducts.fold(
    0,
    (total, product) => total + product.price * quantityFor(product.id),
  );
  double get savings => cartProducts.fold(
    0,
    (total, product) =>
        total +
        (product.originalPrice - product.price) * quantityFor(product.id),
  );
  int quantityFor(String id, {String? flavor}) => flavor != null
      ? _bag[(id, flavor)]?.quantity ?? 0
      : _bag.values
            .where((line) => line.product.id == id)
            .fold(0, (total, line) => total + line.quantity);
  bool isSaved(String id) => _savedIds.contains(id);

  void add(Product product, {String? flavor}) {
    final selectedFlavor =
        flavor ?? (product.flavors.isEmpty ? null : product.flavors.first);
    final key = (product.id, selectedFlavor);
    final quantity = _bag[key]?.quantity ?? 0;
    _bag[key] = BagLine(
      product: product,
      flavor: selectedFlavor,
      quantity: quantity + 1,
    );
    notifyListeners();
  }

  void remove(Product product, {String? flavor}) {
    final matchingKeys = _bag.keys.where(
      (key) => key.$1 == product.id && (flavor == null || key.$2 == flavor),
    );
    if (matchingKeys.isEmpty) return;
    final key = matchingKeys.first;
    final line = _bag[key]!;
    if (line.quantity <= 1) {
      _bag.remove(key);
    } else {
      _bag[key] = BagLine(
        product: product,
        flavor: line.flavor,
        quantity: line.quantity - 1,
      );
    }
    notifyListeners();
  }

  void toggleSaved(Product product) {
    if (!_savedIds.add(product.id)) _savedIds.remove(product.id);
    notifyListeners();
  }

  void setLocation(String location) {
    _location = location;
    notifyListeners();
  }
}

@immutable
class BagLine {
  const BagLine({
    required this.product,
    required this.flavor,
    required this.quantity,
  });
  final Product product;
  final String? flavor;
  final int quantity;
}

class AppScope extends InheritedNotifier<AppController> {
  const AppScope({
    super.key,
    required AppController controller,
    required super.child,
  }) : super(notifier: controller);

  static AppController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope must be above this widget.');
    return scope!.notifier!;
  }
}

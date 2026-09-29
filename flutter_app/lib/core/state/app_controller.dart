import 'dart:collection';

import 'package:flutter/material.dart';

import '../../features/catalog/domain/product.dart';
import '../../features/orders/data/local_order_repository.dart';
import '../../features/orders/domain/order.dart';
import 'delivery_pricing.dart';

/// Customer session state. All catalog, bag, and order data stays local.
class AppController extends ChangeNotifier {
  AppController({LocalOrderRepository? orderRepository})
    : _orderRepository = orderRepository ?? LocalOrderRepository();

  final LocalOrderRepository _orderRepository;
  final Map<(String, String?), BagLine> _bag = {};
  final Set<String> _savedIds = {};
  String _location = 'Indiranagar, Bengaluru';
  DeliveryAddress _deliveryAddress = const DeliveryAddress(
    line1: '42, First Main Road',
    area: 'Indiranagar',
    city: 'Bengaluru',
    postalCode: '560038',
  );
  CheckoutContact _contact = const CheckoutContact(
    name: 'Alex Rao',
    phone: '9876543210',
  );
  PaymentMethod _paymentMethod = PaymentMethod.cashOnDelivery;

  String get location => _location;
  DeliveryAddress get deliveryAddress => _deliveryAddress;
  CheckoutContact get contact => _contact;
  PaymentMethod get paymentMethod => _paymentMethod;
  List<ProtoOrder> get orders => _orderRepository.orders;
  ProtoOrder? orderById(String id) => _orderRepository.getById(id);
  int get cartCount =>
      _bag.values.fold(0, (total, line) => total + line.quantity);
  List<BagLine> get bagLines => List.unmodifiable(_bag.values);
  Set<String> get savedProductIds => UnmodifiableSetView(_savedIds);
  List<Product> get cartProducts => List.unmodifiable(
    {for (final line in _bag.values) line.product.id: line.product}.values,
  );
  double get subtotal => _bag.values.fold(
    0,
    (total, line) => total + line.product.price * line.quantity,
  );
  double get savings => _bag.values.fold(
    0,
    (total, line) =>
        total +
        (line.product.originalPrice - line.product.price) * line.quantity,
  );
  double get deliveryFee => DeliveryPricing.feeFor(subtotal);
  double get total => subtotal + deliveryFee;
  int quantityFor(String id, {String? flavor}) => flavor != null
      ? _bag[(id, flavor)]?.quantity ?? 0
      : _bag.values
            .where((line) => line.product.id == id)
            .fold(0, (total, line) => total + line.quantity);
  bool isSaved(String id) => _savedIds.contains(id);

  void add(Product product, {String? flavor, int quantity = 1}) {
    if (quantity <= 0)
      throw ArgumentError.value(
        quantity,
        'quantity',
        'Must be greater than zero.',
      );
    final selectedFlavor =
        flavor ?? (product.flavors.isEmpty ? null : product.flavors.first);
    if (selectedFlavor != null && !product.flavors.contains(selectedFlavor)) {
      throw ArgumentError.value(
        selectedFlavor,
        'flavor',
        'Choose an available flavor.',
      );
    }
    final key = (product.id, selectedFlavor);
    final currentQuantity = _bag[key]?.quantity ?? 0;
    _bag[key] = BagLine(
      product: product,
      flavor: selectedFlavor,
      quantity: currentQuantity + quantity,
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
    final parts = location.split(',');
    final area = parts.first.trim();
    _deliveryAddress = DeliveryAddress(
      line1: _deliveryAddress.line1,
      area: area,
      city: parts.length > 1 ? parts.last.trim() : _deliveryAddress.city,
      postalCode: switch (area) {
        'Koramangala' => '560034',
        'HSR Layout' => '560102',
        'Indiranagar' => '560038',
        _ => _deliveryAddress.postalCode,
      },
      label: _deliveryAddress.label,
    );
    notifyListeners();
  }

  /// Removes a whole flavor variant rather than decrementing one unit.
  void removeLine(Product product, {String? flavor}) {
    final selectedFlavor =
        flavor ?? (product.flavors.isEmpty ? null : product.flavors.first);
    if (_bag.remove((product.id, selectedFlavor)) != null) notifyListeners();
  }

  ProtoOrder placeOrder({
    required DeliveryAddress address,
    required CheckoutContact contact,
    required PaymentMethod paymentMethod,
  }) {
    final order = _orderRepository.create(
      items: bagLines
          .map(
            (line) => OrderItem(
              product: line.product,
              flavor: line.flavor,
              quantity: line.quantity,
              unitPrice: line.product.price,
            ),
          )
          .toList(),
      address: address,
      contact: contact,
      paymentMethod: paymentMethod,
      deliveryFee: deliveryFee,
    );
    _deliveryAddress = order.address;
    _contact = order.contact;
    _paymentMethod = paymentMethod;
    _location = '${order.address.area}, ${order.address.city}';
    _bag.clear();
    notifyListeners();
    return order;
  }

  ProtoOrder? advanceOrderStatus(String id) {
    final previous = orderById(id);
    final updated = _orderRepository.advanceStatus(id);
    if (updated != previous) notifyListeners();
    return updated;
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

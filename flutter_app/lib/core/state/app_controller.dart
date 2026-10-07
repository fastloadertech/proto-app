import 'dart:collection';

import 'package:flutter/material.dart';

import '../../features/catalog/domain/product.dart';
import '../../features/catalog/domain/catalog_repository.dart';
import '../../features/catalog/data/local_catalog_repository.dart';
import '../../features/auth/domain/auth_repository.dart';
import '../../features/auth/data/local_auth_repository.dart';
import '../../features/orders/data/local_order_repository.dart';
import '../../features/orders/domain/order.dart';
import '../../features/orders/domain/order_repository.dart';
import 'coupon_pricing.dart';
import 'delivery_pricing.dart';

/// Customer session state. All catalog, bag, and order data stays local.
class AppController extends ChangeNotifier {
  AppController({
    OrderRepository? orderRepository,
    CatalogRepository? catalogRepository,
    AuthRepository? authRepository,
  }) : _orderRepository = orderRepository ?? MockOrderRepository(),
       catalog = catalogRepository ?? const LocalCatalogSource(),
       auth = authRepository ?? LocalAuthRepository();

  static const DeliveryAddress _initialAddress = DeliveryAddress(
    line1: '42, First Main Road',
    area: 'Indiranagar',
    city: 'Bengaluru',
    postalCode: '560038',
    id: 'address-1',
  );

  final OrderRepository _orderRepository;
  final CatalogRepository catalog;
  final AuthRepository auth;
  CustomerSession? get currentSession => auth.currentSession;
  Future<void> signIn(String phone, {String? code}) async {
    await auth.login(phone, code: code);
    notifyListeners();
  }

  Future<void> signInDemo(String phone) => signIn(phone);

  Future<CustomerSession?> restoreSession() async {
    final session = await auth.restoreSession();
    notifyListeners();
    return session;
  }

  Future<void> signOut() async {
    await auth.logout();
    notifyListeners();
  }

  Future<void> signOutDemo() => signOut();

  final Map<(String, String?), BagLine> _bag = {};
  final Set<String> _savedIds = {};
  final List<DeliveryAddress> _savedAddresses = [_initialAddress];
  int _nextAddressNumber = 2;
  String _location = 'Indiranagar, Bengaluru';
  DeliveryAddress _deliveryAddress = _initialAddress;
  CheckoutContact _contact = const CheckoutContact(
    name: 'Alex Rao',
    phone: '9876543210',
  );
  PaymentMethod _paymentMethod = PaymentMethod.cashOnDelivery;
  String? _couponCode;
  String? _couponMessage;

  String get location => _location;
  DeliveryAddress get deliveryAddress => _deliveryAddress;
  List<DeliveryAddress> get savedAddresses =>
      List.unmodifiable(_savedAddresses);
  CheckoutContact get contact => _contact;
  PaymentMethod get paymentMethod => _paymentMethod;
  String? get couponCode => _couponCode;
  String? get couponMessage => _couponMessage;
  List<ProtoOrder> get orders => _orderRepository.orders;
  ProtoOrder? orderById(String id) => _orderRepository.getById(id);
  Future<List<ProtoOrder>> loadOrders() => _orderRepository.loadOrders();
  Future<ProtoOrder?> loadOrder(String id) => _orderRepository.loadById(id);
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
  double get couponDiscount => _couponCode == null
      ? 0
      : CouponPricing.evaluate(_couponCode!, subtotal).discount;
  double get total {
    final amount = subtotal + deliveryFee - couponDiscount;
    return amount < 0 ? 0 : amount;
  }

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
    if (!product.isAvailable) {
      throw StateError('${product.name} is temporarily unavailable.');
    }
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
      id: _deliveryAddress.id,
    );
    _replaceSavedAddress(_deliveryAddress);
    notifyListeners();
  }

  void _replaceSavedAddress(DeliveryAddress address) {
    final index = _savedAddresses.indexWhere((saved) => saved.id == address.id);
    if (index >= 0) _savedAddresses[index] = address;
  }

  void selectSavedAddress(String id) {
    final index = _savedAddresses.indexWhere((address) => address.id == id);
    if (index < 0) {
      throw ArgumentError.value(id, 'id', 'Choose a saved address.');
    }
    final address = _savedAddresses[index];
    _deliveryAddress = address;
    _location = '${address.area}, ${address.city}';
    notifyListeners();
  }

  /// Kept for existing callers that select the first address with a label.
  void selectDeliveryAddress(String label) {
    final index = _savedAddresses.indexWhere(
      (address) => address.label == label,
    );
    if (index < 0) {
      throw ArgumentError.value(label, 'label', 'Choose a saved address.');
    }
    selectSavedAddress(_savedAddresses[index].id);
  }

  void saveDeliveryAddress(DeliveryAddress address) {
    final normalized = address.normalized;
    if (!normalized.isValid ||
        !const {'Home', 'Work', 'Other'}.contains(normalized.label)) {
      throw ArgumentError.value(address, 'address', 'Enter a valid address.');
    }
    final DeliveryAddress saved;
    if (normalized.id.isEmpty) {
      saved = normalized.withId('address-${_nextAddressNumber++}');
      _savedAddresses.add(saved);
    } else {
      final index = _savedAddresses.indexWhere(
        (address) => address.id == normalized.id,
      );
      if (index < 0) {
        throw ArgumentError.value(address, 'address', 'Unknown saved address.');
      }
      saved = normalized;
      _savedAddresses[index] = saved;
    }
    _deliveryAddress = saved;
    _location = '${saved.area}, ${saved.city}';
    notifyListeners();
  }

  bool applyCoupon(String input) {
    if (input.trim().isEmpty) {
      _couponMessage = 'Enter a coupon code.';
      notifyListeners();
      return false;
    }
    final evaluation = CouponPricing.evaluate(input, subtotal);
    if (!evaluation.isApplied) {
      _couponMessage = evaluation.message;
      notifyListeners();
      return false;
    }
    _couponCode = evaluation.code;
    _couponMessage = null;
    notifyListeners();
    return true;
  }

  void removeCoupon() {
    if (_couponCode == null && _couponMessage == null) return;
    _couponCode = null;
    _couponMessage = null;
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
    final discount = couponDiscount;
    final addressForOrder = _addressForOrder(address);
    final order = _orderRepository.create(
      items: _orderItems(),
      address: addressForOrder,
      contact: contact,
      paymentMethod: paymentMethod,
      deliveryFee: deliveryFee,
      discount: discount,
      promoCode: discount > 0 ? _couponCode : null,
    );
    _completeOrder(order, paymentMethod);
    return order;
  }

  /// Checkout awaits this boundary so an eventual HTTP order repository can
  /// fail without clearing the bag or changing the selected address.
  Future<ProtoOrder> submitOrder({
    required DeliveryAddress address,
    required CheckoutContact contact,
    required PaymentMethod paymentMethod,
  }) async {
    final discount = couponDiscount;
    final items = _orderItems();
    final destination = _addressForOrder(address);
    final promoCode = discount > 0 ? _couponCode : null;
    final repository = _orderRepository;
    final order = repository is AsyncOrderRepository
        ? await (repository as AsyncOrderRepository).createAsync(
            items: items,
            address: destination,
            contact: contact,
            paymentMethod: paymentMethod,
            deliveryFee: deliveryFee,
            discount: discount,
            promoCode: promoCode,
          )
        : repository.create(
            items: items,
            address: destination,
            contact: contact,
            paymentMethod: paymentMethod,
            deliveryFee: deliveryFee,
            discount: discount,
            promoCode: promoCode,
          );
    _completeOrder(order, paymentMethod);
    return order;
  }

  List<OrderItem> _orderItems() => bagLines
      .map(
        (line) => OrderItem(
          product: line.product,
          flavor: line.flavor,
          quantity: line.quantity,
          unitPrice: line.product.price,
        ),
      )
      .toList();

  DeliveryAddress _addressForOrder(DeliveryAddress address) {
    final normalized = address.normalized;
    if (normalized.id.isNotEmpty) return normalized;
    final needsNewId = normalized.label != _deliveryAddress.label;
    return normalized.withId(
      needsNewId ? 'address-$_nextAddressNumber' : _deliveryAddress.id,
    );
  }

  void _completeOrder(ProtoOrder order, PaymentMethod paymentMethod) {
    final needsNewAddressId = order.address.id == 'address-$_nextAddressNumber';
    if (needsNewAddressId) _nextAddressNumber++;
    final savedAddress = order.address;
    final savedIndex = _savedAddresses.indexWhere(
      (address) => address.id == savedAddress.id,
    );
    if (savedIndex < 0) {
      _savedAddresses.add(savedAddress);
    } else {
      _savedAddresses[savedIndex] = savedAddress;
    }
    _deliveryAddress = order.address;
    _contact = order.contact;
    _paymentMethod = paymentMethod;
    _location = '${order.address.area}, ${order.address.city}';
    _bag.clear();
    _couponCode = null;
    _couponMessage = null;
    notifyListeners();
  }

  ProtoOrder? advanceOrderStatus(String id) {
    final previous = orderById(id);
    final updated = _orderRepository.advanceStatus(id);
    if (updated != previous) notifyListeners();
    return updated;
  }

  ProtoOrder? updateOrderStatus(String id, OrderStatus next) {
    final previous = orderById(id);
    final updated = _orderRepository.updateStatus(id, next);
    if (updated != previous) notifyListeners();
    return updated;
  }

  ProtoOrder? cancelOrder(String id) =>
      updateOrderStatus(id, OrderStatus.cancelled);

  void resetDemoOrders() {
    if (_orderRepository.orders.isEmpty) return;
    _orderRepository.reset();
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

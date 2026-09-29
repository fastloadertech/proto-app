import '../../catalog/domain/product.dart';

enum PaymentMethod {
  cashOnDelivery,
  mockUpi,
  mockCard;

  String get label => switch (this) {
    cashOnDelivery => 'Pay on delivery',
    mockUpi => 'UPI demo',
    mockCard => 'Card demo',
  };
}

enum OrderStatus {
  orderPlaced,
  preparing,
  outForDelivery,
  delivered;

  String get label => switch (this) {
    orderPlaced => 'Order Placed',
    preparing => 'Preparing',
    outForDelivery => 'Out for Delivery',
    delivered => 'Delivered',
  };

  String get description => switch (this) {
    orderPlaced => 'Your fuel is on the list. We have your order.',
    preparing => 'Your essentials are being packed with care.',
    outForDelivery => 'Your bag is on its way to your door.',
    delivered => 'Good fuel, delivered. Keep showing up.',
  };
}

/// A local delivery destination, kept separately from contact information.
class DeliveryAddress {
  const DeliveryAddress({
    required this.line1,
    required this.area,
    required this.city,
    required this.postalCode,
    this.label = 'Home',
  });

  final String line1;
  final String area;
  final String city;
  final String postalCode;
  final String label;

  bool get isValid =>
      line1.trim().length >= 3 &&
      area.trim().isNotEmpty &&
      city.trim().isNotEmpty &&
      RegExp(r'^[1-9]\d{5}$').hasMatch(postalCode.trim());

  String get formatted => '$line1\n$area, $city — $postalCode';

  DeliveryAddress get normalized => DeliveryAddress(
    line1: line1.trim(),
    area: area.trim(),
    city: city.trim(),
    postalCode: postalCode.trim(),
    label: label.trim(),
  );
}

class CheckoutContact {
  const CheckoutContact({
    required this.name,
    required this.phone,
    this.email = '',
  });
  final String name;
  final String phone;
  final String email;

  bool get isValid =>
      name.trim().length >= 2 &&
      RegExp(r'^\d{10}$').hasMatch(phone.trim()) &&
      (email.trim().isEmpty ||
          RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email.trim()));

  CheckoutContact get normalized => CheckoutContact(
    name: name.trim(),
    phone: phone.trim(),
    email: email.trim(),
  );
}

/// Unit price and quantity are captured when an order is created.
class OrderItem {
  const OrderItem({
    required this.product,
    required this.flavor,
    required this.quantity,
    required this.unitPrice,
  });
  final Product product;
  final String? flavor;
  final int quantity;
  final double unitPrice;
  double get total => unitPrice * quantity;
}

class ProtoOrder {
  ProtoOrder({
    required this.id,
    required this.createdAt,
    required this.estimatedDeliveryAt,
    required List<OrderItem> items,
    required this.address,
    required this.contact,
    required this.paymentMethod,
    required this.deliveryFee,
    this.status = OrderStatus.orderPlaced,
  }) : items = List.unmodifiable(items);

  final String id;
  final DateTime createdAt;
  final DateTime estimatedDeliveryAt;
  final List<OrderItem> items;
  final DeliveryAddress address;
  final CheckoutContact contact;
  final PaymentMethod paymentMethod;
  final double deliveryFee;
  final OrderStatus status;

  double get subtotal => items.fold(0, (sum, item) => sum + item.total);
  double get total => subtotal + deliveryFee;
  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);

  ProtoOrder withStatus(OrderStatus next) => ProtoOrder(
    id: id,
    createdAt: createdAt,
    estimatedDeliveryAt: estimatedDeliveryAt,
    items: items,
    address: address,
    contact: contact,
    paymentMethod: paymentMethod,
    deliveryFee: deliveryFee,
    status: next,
  );
}

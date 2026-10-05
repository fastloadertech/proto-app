import '../../catalog/domain/product.dart';

enum PaymentMethod {
  cashOnDelivery,
  mockUpi,
  online,
  mockCard;

  String get label => switch (this) {
    cashOnDelivery => 'Pay on delivery',
    mockUpi => 'UPI demo',
    online => 'Online payment',
    mockCard => 'Card demo',
  };
}

enum PaymentStatus {
  notCharged,
  pending,
  paid,
  failed,
  refunded;

  String get label => switch (this) {
    notCharged => 'Not charged · demo',
    pending => 'Payment pending',
    paid => 'Paid',
    failed => 'Payment failed',
    refunded => 'Refunded',
  };
}

enum OrderStatus {
  pending,
  confirmed,
  preparing,
  outForDelivery,
  delivered,
  cancelled;

  static const deliveryStages = [
    pending,
    confirmed,
    preparing,
    outForDelivery,
    delivered,
  ];

  bool get canCancel => this == pending || this == confirmed;
  bool get isTerminal => this == delivered || this == cancelled;

  bool canTransitionTo(OrderStatus next) {
    if (next == cancelled) return canCancel;
    final currentIndex = deliveryStages.indexOf(this);
    return currentIndex >= 0 &&
        currentIndex < deliveryStages.length - 1 &&
        deliveryStages[currentIndex + 1] == next;
  }

  String get label => switch (this) {
    pending => 'Pending',
    confirmed => 'Confirmed',
    preparing => 'Preparing',
    outForDelivery => 'Out for Delivery',
    delivered => 'Delivered',
    cancelled => 'Cancelled',
  };

  String get description => switch (this) {
    pending => 'Your fuel is on the list. We have your order.',
    confirmed => 'Your order is confirmed in this local demo.',
    preparing => 'Your essentials are being packed with care.',
    outForDelivery => 'Your bag is on its way to your door.',
    delivered => 'Good fuel, delivered. Keep showing up.',
    cancelled => 'This demo order has been cancelled.',
  };
}

/// A replaceable delivery-service snapshot; no driver is contacted in the demo.
class DeliveryAssignment {
  const DeliveryAssignment({
    required this.driverName,
    required this.vehicleType,
    required this.vehicleDetails,
    required this.contactNumber,
    required this.estimatedArrivalAt,
    this.deliveryJobId,
  });

  final String driverName;
  final String vehicleType;
  final String vehicleDetails;
  final String contactNumber;
  final DateTime estimatedArrivalAt;
  final String? deliveryJobId;
}

/// A local delivery destination, kept separately from contact information.
class DeliveryAddress {
  const DeliveryAddress({
    required this.line1,
    required this.area,
    required this.city,
    required this.postalCode,
    this.label = 'Home',
    this.id = '',
  });

  final String line1;
  final String area;
  final String city;
  final String postalCode;
  final String label;

  /// Session-local identity for a saved address. Empty for a new draft.
  final String id;

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
    id: id,
  );

  DeliveryAddress withId(String value) => DeliveryAddress(
    line1: line1,
    area: area,
    city: city,
    postalCode: postalCode,
    label: label,
    id: value,
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
  OrderItem({
    required Product product,
    required this.flavor,
    required this.quantity,
    required this.unitPrice,
  }) : product = Product(
         id: product.id,
         name: product.name,
         brand: product.brand,
         categoryId: product.categoryId,
         price: product.price,
         originalPrice: product.originalPrice,
         weightLabel: product.weightLabel,
         subtitle: product.subtitle,
         description: product.description,
         proteinGrams: product.proteinGrams,
         servings: product.servings,
         rating: product.rating,
         reviewCount: product.reviewCount,
         badge: product.badge,
         accentColor: product.accentColor,
         form: product.form,
         flavors: List.unmodifiable(product.flavors),
         isAvailable: product.isAvailable,
       ),
       productId = product.id,
       productName = product.name;

  /// The copied product provides stable artwork without reading the catalog.
  final Product product;
  final String productId;
  final String productName;
  final String? flavor;
  final int quantity;
  final double unitPrice;
  double get subtotal => unitPrice * quantity;
  double get total => subtotal;
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
    this.paymentStatus = PaymentStatus.notCharged,
    this.discount = 0,
    this.promoCode,
    this.status = OrderStatus.pending,
    List<OrderStatus>? statusHistory,
    this.deliveryAssignment,
  }) : items = List.unmodifiable(items),
       statusHistory = List.unmodifiable(statusHistory ?? [status]);

  final String id;
  final DateTime createdAt;
  final DateTime estimatedDeliveryAt;
  final List<OrderItem> items;
  final DeliveryAddress address;
  final CheckoutContact contact;
  final PaymentMethod paymentMethod;
  final PaymentStatus paymentStatus;
  final double deliveryFee;
  final double discount;
  final String? promoCode;
  final OrderStatus status;
  final List<OrderStatus> statusHistory;
  final DeliveryAssignment? deliveryAssignment;

  double get subtotal => items.fold(0, (sum, item) => sum + item.total);
  double get total => subtotal + deliveryFee - discount;
  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);

  ProtoOrder withStatus(
    OrderStatus next, {
    DeliveryAssignment? deliveryAssignment,
  }) {
    if (!status.canTransitionTo(next)) {
      throw StateError(
        'Cannot move an order from ${status.label} to ${next.label}.',
      );
    }
    return ProtoOrder(
      id: id,
      createdAt: createdAt,
      estimatedDeliveryAt: estimatedDeliveryAt,
      items: items,
      address: address,
      contact: contact,
      paymentMethod: paymentMethod,
      paymentStatus: paymentStatus,
      deliveryFee: deliveryFee,
      discount: discount,
      promoCode: promoCode,
      status: next,
      statusHistory: [...statusHistory, next],
      deliveryAssignment: deliveryAssignment ?? this.deliveryAssignment,
    );
  }
}

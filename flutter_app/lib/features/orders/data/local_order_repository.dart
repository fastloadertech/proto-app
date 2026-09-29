import '../domain/order.dart';

/// In-memory mock order store. No network, persistence, or payment processing.
class LocalOrderRepository {
  LocalOrderRepository({DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final DateTime Function() _clock;
  final List<ProtoOrder> _orders = [];
  int _sequence = 0;

  List<ProtoOrder> get orders => List.unmodifiable(_orders);

  ProtoOrder? getById(String id) {
    for (final order in _orders) {
      if (order.id == id) return order;
    }
    return null;
  }

  ProtoOrder create({
    required List<OrderItem> items,
    required DeliveryAddress address,
    required CheckoutContact contact,
    required PaymentMethod paymentMethod,
    required double deliveryFee,
  }) {
    if (items.isEmpty)
      throw StateError('Add something to your bag before checkout.');
    if (!address.isValid || !contact.isValid)
      throw ArgumentError('Complete your delivery and contact details.');
    if (!deliveryFee.isFinite ||
        deliveryFee < 0 ||
        items.any(
          (item) =>
              item.quantity <= 0 ||
              !item.unitPrice.isFinite ||
              item.unitPrice < 0,
        )) {
      throw ArgumentError('Order prices and quantities must be valid.');
    }
    final createdAt = _clock();
    final date =
        '${createdAt.year}${createdAt.month.toString().padLeft(2, '0')}${createdAt.day.toString().padLeft(2, '0')}';
    final order = ProtoOrder(
      id: 'PR-$date-${(++_sequence).toString().padLeft(4, '0')}',
      createdAt: createdAt,
      estimatedDeliveryAt: createdAt.add(const Duration(minutes: 12)),
      items: items,
      address: address.normalized,
      contact: contact.normalized,
      paymentMethod: paymentMethod,
      deliveryFee: deliveryFee,
    );
    _orders.insert(0, order);
    return order;
  }

  ProtoOrder? advanceStatus(String id) {
    final index = _orders.indexWhere((order) => order.id == id);
    if (index < 0) return null;
    final current = _orders[index];
    if (current.status == OrderStatus.delivered) return current;
    final next = current.withStatus(
      OrderStatus.values[current.status.index + 1],
    );
    _orders[index] = next;
    return next;
  }
}

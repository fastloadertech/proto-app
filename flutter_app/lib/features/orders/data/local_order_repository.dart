import '../domain/order.dart';
import '../domain/order_repository.dart';

/// In-memory mock order store. No network, persistence, or payment processing.
class LocalOrderRepository implements OrderRepository {
  LocalOrderRepository({DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final DateTime Function() _clock;
  final List<ProtoOrder> _orders = [];
  int _sequence = 0;

  @override
  List<ProtoOrder> get orders => List.unmodifiable(_orders);

  @override
  ProtoOrder? getById(String id) {
    for (final order in _orders) {
      if (order.id == id) return order;
    }
    return null;
  }

  @override
  Future<List<ProtoOrder>> loadOrders() async => orders;

  @override
  Future<ProtoOrder?> loadById(String id) async => getById(id);

  @override
  ProtoOrder create({
    required List<OrderItem> items,
    required DeliveryAddress address,
    required CheckoutContact contact,
    required PaymentMethod paymentMethod,
    required double deliveryFee,
    double discount = 0,
    String? promoCode,
  }) {
    if (items.isEmpty)
      throw StateError('Add something to your bag before checkout.');
    if (!address.isValid || !contact.isValid)
      throw ArgumentError('Complete your delivery and contact details.');
    final subtotal = items.fold<double>(0, (sum, item) => sum + item.total);
    if (!deliveryFee.isFinite ||
        deliveryFee < 0 ||
        !discount.isFinite ||
        discount < 0 ||
        discount > subtotal ||
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
      discount: discount,
      promoCode: discount > 0 ? promoCode?.trim().toUpperCase() : null,
    );
    _orders.insert(0, order);
    return order;
  }

  @override
  ProtoOrder? updateStatus(String id, OrderStatus next) {
    final index = _orders.indexWhere((order) => order.id == id);
    if (index < 0) return null;
    final current = _orders[index];
    if (current.status == next) return current;
    final updated = current.withStatus(
      next,
      deliveryAssignment: next == OrderStatus.outForDelivery
          ? DeliveryAssignment(
              driverName: 'Aarav Kumar',
              vehicleType: 'Electric scooter',
              vehicleDetails: 'KA 03 AB 2468',
              contactNumber: '9000000000',
              estimatedArrivalAt: current.estimatedDeliveryAt,
            )
          : null,
    );
    _orders[index] = updated;
    return updated;
  }

  @override
  ProtoOrder? advanceStatus(String id) {
    final current = getById(id);
    if (current == null) return null;
    if (current.status.isTerminal) return current;
    final currentIndex = OrderStatus.deliveryStages.indexOf(current.status);
    return updateStatus(id, OrderStatus.deliveryStages[currentIndex + 1]);
  }

  @override
  ProtoOrder? cancel(String id) => updateStatus(id, OrderStatus.cancelled);

  @override
  void reset() => _orders.clear();
}

/// Preferred name for the in-memory implementation; the old name remains for
/// existing callers and tests.
class MockOrderRepository extends LocalOrderRepository {
  MockOrderRepository({super.clock});
}

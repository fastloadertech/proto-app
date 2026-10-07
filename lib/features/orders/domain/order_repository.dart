import 'order.dart';

/// The customer-facing order store contract. A future API implementation can
/// replace the local demo without changing checkout or order screens.
abstract class OrderRepository {
  List<ProtoOrder> get orders;
  ProtoOrder? getById(String id);
  Future<List<ProtoOrder>> loadOrders();
  Future<ProtoOrder?> loadById(String id);

  ProtoOrder create({
    required List<OrderItem> items,
    required DeliveryAddress address,
    required CheckoutContact contact,
    required PaymentMethod paymentMethod,
    required double deliveryFee,
    double discount = 0,
    String? promoCode,
  });

  ProtoOrder? updateStatus(String id, OrderStatus next);
  ProtoOrder? advanceStatus(String id);
  ProtoOrder? cancel(String id);
  void reset();
}

/// Optional asynchronous submission path for a future network repository.
/// Existing OrderRepository implementations remain source-compatible.
abstract interface class AsyncOrderRepository {
  Future<ProtoOrder> createAsync({
    required List<OrderItem> items,
    required DeliveryAddress address,
    required CheckoutContact contact,
    required PaymentMethod paymentMethod,
    required double deliveryFee,
    double discount = 0,
    String? promoCode,
  });
}

import 'package:flutter/material.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_failure.dart';
import '../../../core/api/api_models.dart';
import '../../../core/api/api_routes.dart';
import '../../../core/api/shared_backend_contract.dart';
import '../../auth/domain/auth_repository.dart';
import '../../catalog/domain/catalog_repository.dart';
import '../../catalog/domain/product.dart';
import '../domain/order.dart';
import '../domain/order_repository.dart';

/// Opt-in order adapter for the proposed customer API. The app still injects
/// MockOrderRepository. A future rollout must supply a transport, agree the
/// commerce response shape, and bootstrap catalog/auth before using this.
class ApiOrderRepository implements OrderRepository, AsyncOrderRepository {
  ApiOrderRepository({
    required this.client,
    required this.auth,
    required this.catalog,
  });
  final ApiClient client;
  final AuthRepository auth;
  final CatalogRepository catalog;
  final List<ProtoOrder> _orders = [];
  String? get _token {
    final session = auth.currentSession;
    return session?.isAuthenticated == true ? session!.accessToken : null;
  }

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
  Future<List<ProtoOrder>> loadOrders() async {
    final body = await client.get(ApiRoutes.orders, accessToken: _token);
    final next = ApiClient.objects(body).map(_decodeOrder).toList();
    _orders
      ..clear()
      ..addAll(next);
    return orders;
  }

  @override
  Future<ProtoOrder?> loadById(String id) async {
    final body = await client.get(ApiRoutes.order(id), accessToken: _token);
    final order = _decodeOrder(ApiClient.object(body));
    _upsert(order);
    return order;
  }

  @override
  Future<ProtoOrder> createAsync({
    required List<OrderItem> items,
    required DeliveryAddress address,
    required CheckoutContact contact,
    required PaymentMethod paymentMethod,
    required double deliveryFee,
    double discount = 0,
    String? promoCode,
  }) async {
    if (address.id.isEmpty) {
      throw const ApiFailure(
        ApiFailureKind.validation,
        message: 'Select a saved delivery address.',
      );
    }
    final request = CreateOrderRequestDto(
      addressId: address.id,
      paymentMethod: paymentMethod == PaymentMethod.cashOnDelivery
          ? 'CASH_ON_DELIVERY'
          : 'ONLINE',
      items: items
          .map(
            (item) => CreateOrderLineDto(
              productId: item.productId,
              quantity: item.quantity,
              flavor: item.flavor,
            ),
          )
          .toList(),
      promoCode: promoCode,
    );
    // Server owns pricing and totals; local amounts are not sent.
    final body = await client.post(
      ApiRoutes.orders,
      body: request.toJson(),
      accessToken: _token,
    );
    final order = _decodeOrder(ApiClient.object(body));
    _upsert(order);
    return order;
  }

  Future<ProtoOrder> cancelAsync(String id) async {
    final body = await client.post(
      ApiRoutes.cancelOrder(id),
      accessToken: _token,
    );
    final order = _decodeOrder(ApiClient.object(body));
    _upsert(order);
    return order;
  }

  Future<OrderStatus> loadStatus(String id) async {
    final body = ApiClient.object(
      await client.get(ApiRoutes.orderStatus(id), accessToken: _token),
    );
    return _status(body['status'] as String);
  }

  void _upsert(ProtoOrder order) {
    _orders.removeWhere((item) => item.id == order.id);
    _orders.insert(0, order);
  }

  ProtoOrder _decodeOrder(Map<String, dynamic> json) {
    final dto = json.containsKey('subtotal')
        ? SharedBackendContract.order(json)
        : OrderDto.fromJson(json);
    final address = dto.address;
    final payment = dto.payment;
    final customer = dto.customer;
    if (address == null ||
        payment == null ||
        (customer == null && address.recipientName == null) ||
        dto.estimatedDeliveryAt == null &&
            dto.delivery?.estimatedMinutes == null) {
      throw const ApiFailure(
        ApiFailureKind.unknown,
        message: 'The order response is missing delivery details.',
      );
    }
    final eta =
        dto.estimatedDeliveryAt ??
        dto.createdAt.add(Duration(minutes: dto.delivery!.estimatedMinutes!));
    final destination = DeliveryAddress(
      id: address.id,
      label: address.label,
      line1: address.line1,
      area: address.area,
      city: address.city,
      postalCode: address.postalCode,
    );
    final assignment = dto.driver ?? dto.delivery?.assignment;
    return ProtoOrder(
      id: dto.id,
      createdAt: dto.createdAt,
      estimatedDeliveryAt: eta,
      items: dto.items
          .map(
            (item) => OrderItem(
              product: _productSnapshot(item),
              flavor: item.flavor,
              quantity: item.quantity,
              unitPrice: item.unitPricePaise / 100,
            ),
          )
          .toList(),
      address: destination,
      contact: CheckoutContact(
        name: customer?.name ?? address.recipientName!,
        phone: address.phone ?? customer?.phone ?? '',
      ),
      paymentMethod: _paymentMethod(payment.method),
      paymentStatus: _paymentStatus(payment.status),
      deliveryFee: dto.deliveryFeePaise / 100,
      discount: dto.discountPaise / 100,
      status: _status(dto.status),
      deliveryAssignment: assignment == null
          ? null
          : DeliveryAssignment(
              deliveryJobId: assignment.deliveryJobId,
              driverName: assignment.driverName,
              vehicleType: assignment.vehicle,
              vehicleDetails: '',
              contactNumber: assignment.contact ?? '',
              estimatedArrivalAt: assignment.eta ?? eta,
            ),
    );
  }

  Product _productSnapshot(OrderItemDto item) =>
      catalog.getById(item.productId) ??
      Product(
        id: item.productId,
        name: item.name,
        brand: '',
        categoryId: '',
        price: item.unitPricePaise / 100,
        originalPrice: item.unitPricePaise / 100,
        weightLabel: '',
        subtitle: '',
        description: '',
        proteinGrams: 0,
        servings: 0,
        rating: 0,
        reviewCount: 0,
        badge: '',
        accentColor: const Color(0xFFB9ED54),
        form: ProductForm.pouch,
        flavors: item.flavor == null ? const [] : [item.flavor!],
      );

  OrderStatus _status(String value) => switch (value.toUpperCase()) {
    'PLACED' || 'PENDING' => OrderStatus.pending,
    'CONFIRMED' => OrderStatus.confirmed,
    'PREPARING' || 'READY_FOR_PICKUP' => OrderStatus.preparing,
    'OUT_FOR_DELIVERY' => OrderStatus.outForDelivery,
    'DELIVERED' => OrderStatus.delivered,
    'CANCELLED' => OrderStatus.cancelled,
    _ => throw ApiFailure(
      ApiFailureKind.unknown,
      message: 'Unknown order status: $value',
    ),
  };
  PaymentMethod _paymentMethod(String value) => switch (value.toUpperCase()) {
    'CASH_ON_DELIVERY' => PaymentMethod.cashOnDelivery,
    'ONLINE' => PaymentMethod.online,
    'MOCK_UPI' || 'UPI' => PaymentMethod.mockUpi,
    'MOCK_CARD' || 'CARD' => PaymentMethod.mockCard,
    _ => throw ApiFailure(
      ApiFailureKind.unknown,
      message: 'Unknown payment method: $value',
    ),
  };
  PaymentStatus _paymentStatus(String value) => switch (value.toUpperCase()) {
    'PAID' => PaymentStatus.paid,
    'FAILED' => PaymentStatus.failed,
    'REFUNDED' => PaymentStatus.refunded,
    'PENDING' || 'AUTHORIZED' => PaymentStatus.pending,
    'NOT_CHARGED' => PaymentStatus.notCharged,
    _ => throw ApiFailure(
      ApiFailureKind.unknown,
      message: 'Unknown payment status: $value',
    ),
  };

  @override
  ProtoOrder create({
    required List<OrderItem> items,
    required DeliveryAddress address,
    required CheckoutContact contact,
    required PaymentMethod paymentMethod,
    required double deliveryFee,
    double discount = 0,
    String? promoCode,
  }) => throw UnsupportedError('Use createAsync for API orders.');
  @override
  ProtoOrder? updateStatus(String id, OrderStatus next) =>
      throw UnsupportedError('Order status comes from the shared backend.');
  @override
  ProtoOrder? advanceStatus(String id) =>
      throw UnsupportedError('Order status comes from the shared backend.');
  @override
  ProtoOrder? cancel(String id) =>
      throw UnsupportedError('Use cancelAsync for API orders.');
  @override
  void reset() => _orders.clear();
}

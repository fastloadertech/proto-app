import 'package:flutter/material.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_failure.dart';
import '../../../core/api/live_order_contract.dart';
import '../../../core/api/api_models.dart';
import '../../../core/api/api_routes.dart';
import '../../../core/api/shared_backend_contract.dart';
import '../../auth/domain/auth_repository.dart';
import '../../catalog/domain/catalog_repository.dart';
import '../../catalog/domain/product.dart';
import '../domain/order.dart';
import '../domain/order_repository.dart';

/// Opt-in adapter for the implemented customer order endpoints. Local orders
/// remain the default repository selected by ProtoApp.
class ApiOrderRepository
    implements OrderRepository, AsyncOrderRepository, RemoteOrderRepository {
  ApiOrderRepository({
    required this.client,
    required this.auth,
    required this.catalog,
  });
  final ApiClient client;
  final AuthRepository auth;
  final CatalogRepository catalog;
  final List<ProtoOrder> _orders = [];
  String get _token {
    final session = auth.currentSession;
    if (session?.isAuthenticated != true || session?.accessToken == null) {
      throw const ApiFailure(
        ApiFailureKind.authentication,
        message: 'Please sign in to view or place orders.',
      );
    }
    return session!.accessToken!;
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
    final next = ApiClient.objects(body).map(_decodeOrder).toList()
      ..sort((a, b) {
        final time = b.createdAt.compareTo(a.createdAt);
        return time != 0 ? time : b.id.compareTo(a.id);
      });
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
    if (items.isEmpty || !address.isValid || !contact.isValid) {
      throw const ApiFailure(
        ApiFailureKind.validation,
        message: 'Check your bag and delivery details.',
      );
    }
    // The backend accepts each product once. Proto's local bag can carry the
    // same product in multiple flavors; combine quantities for this contract.
    final quantities = <String, int>{};
    for (final item in items) {
      quantities.update(
        item.productId,
        (quantity) => quantity + item.quantity,
        ifAbsent: () => item.quantity,
      );
    }
    if (quantities.values.any((quantity) => quantity < 1 || quantity > 99)) {
      throw const ApiFailure(
        ApiFailureKind.validation,
        message: 'Choose between 1 and 99 of each product.',
      );
    }
    final request = CreateLiveOrderRequestDto(
      items: [
        for (final entry in quantities.entries)
          CreateLiveOrderItemDto(productId: entry.key, quantity: entry.value),
      ],
      address: LiveOrderAddressDto(
        line1: address.line1.trim(),
        line2: address.area.trim(),
        city: address.city.trim(),
        postalCode: address.postalCode.trim(),
        recipientName: contact.name.trim(),
        phone: '+91${contact.phone.trim()}',
      ),
    );
    // The server owns prices, fee, and total. Demo payment/coupons are not sent.
    final body = await client.post(
      ApiRoutes.orders,
      body: request.toJson(),
      accessToken: _token,
    );
    final order = _decodeOrder(
      ApiClient.object(body),
      selectedAddress: address,
      selectedContact: contact,
      selectedPaymentMethod: paymentMethod,
    );
    _upsert(order);
    return order;
  }

  void _upsert(ProtoOrder order) {
    _orders.removeWhere((item) => item.id == order.id);
    _orders.insert(0, order);
  }

  ProtoOrder _decodeOrder(
    Map<String, dynamic> json, {
    DeliveryAddress? selectedAddress,
    CheckoutContact? selectedContact,
    PaymentMethod? selectedPaymentMethod,
  }) {
    if (!json.containsKey('payment') && !json.containsKey('deliveryJob')) {
      try {
        return _decodeLiveOrder(
          LiveOrderDto.fromJson(json),
          selectedAddress: selectedAddress,
          selectedContact: selectedContact,
          selectedPaymentMethod: selectedPaymentMethod,
        );
      } on ApiFailure {
        rethrow;
      } catch (_) {
        throw const ApiFailure(
          ApiFailureKind.unknown,
          message: 'The order service returned an unexpected response.',
        );
      }
    }
    return _decodeLegacyOrder(json);
  }

  ProtoOrder _decodeLiveOrder(
    LiveOrderDto dto, {
    DeliveryAddress? selectedAddress,
    CheckoutContact? selectedContact,
    PaymentMethod? selectedPaymentMethod,
  }) {
    if (dto.currency != 'INR') {
      throw const ApiFailure(
        ApiFailureKind.unknown,
        message: 'The order service returned an unsupported currency.',
      );
    }
    final address = DeliveryAddress(
      id: selectedAddress?.id ?? '',
      label: selectedAddress?.label ?? 'Home',
      line1: dto.address.line1,
      area: dto.address.line2 ?? dto.address.state ?? '',
      city: dto.address.city,
      postalCode: dto.address.postalCode ?? '',
    );
    final status = _status(dto.status);
    final stageIndex = OrderStatus.liveStages.indexOf(status);
    return ProtoOrder(
      id: dto.id,
      reference: dto.reference,
      createdAt: dto.createdAt,
      updatedAt: dto.updatedAt,
      // The Day 11 backend has no ETA. Live UI hides this legacy field.
      estimatedDeliveryAt: dto.createdAt,
      items: [
        for (final item in dto.items)
          OrderItem(
            product: _productSnapshot(
              productId: item.productId,
              name: item.productName,
              unitPrice: item.unitPricePaise / 100,
            ),
            flavor: null,
            quantity: item.quantity,
            unitPrice: item.unitPricePaise / 100,
            lineTotal: item.lineTotalPaise / 100,
          ),
      ],
      address: address,
      contact: CheckoutContact(
        name:
            dto.address.recipientName ??
            selectedContact?.name ??
            auth.currentSession?.name ??
            'Customer',
        phone:
            dto.address.phone ??
            selectedContact?.phone ??
            auth.currentSession?.phone ??
            '',
      ),
      // Payment is not part of the Day 11 API. The selection is only a UI
      // preview and is hidden when orders are later loaded from the server.
      paymentMethod: selectedPaymentMethod ?? PaymentMethod.cashOnDelivery,
      paymentStatus: PaymentStatus.notCharged,
      deliveryFee: dto.deliveryFeePaise / 100,
      status: status,
      statusHistory: status == OrderStatus.cancelled
          ? const [OrderStatus.pending, OrderStatus.cancelled]
          : stageIndex < 0
          ? [status]
          : OrderStatus.liveStages.take(stageIndex + 1).toList(),
      isLive: true,
      serverSubtotalPaise: dto.subtotalPaise,
      serverTotalPaise: dto.totalPaise,
    );
  }

  ProtoOrder _decodeLegacyOrder(Map<String, dynamic> json) {
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
              product: _productSnapshot(
                productId: item.productId,
                name: item.name,
                unitPrice: item.unitPricePaise / 100,
              ),
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

  Product _productSnapshot({
    required String productId,
    required String name,
    required double unitPrice,
  }) {
    final artwork = catalog.getById(productId);
    return Product(
      id: productId,
      name: name,
      brand: artwork?.brand ?? 'PROTO',
      categoryId: artwork?.categoryId ?? '',
      price: unitPrice,
      originalPrice: unitPrice,
      weightLabel: artwork?.weightLabel ?? '',
      subtitle: artwork?.subtitle ?? '',
      description: artwork?.description ?? '',
      proteinGrams: artwork?.proteinGrams ?? 0,
      servings: artwork?.servings ?? 0,
      rating: artwork?.rating ?? 0,
      reviewCount: artwork?.reviewCount ?? 0,
      badge: artwork?.badge ?? '',
      accentColor: artwork?.accentColor ?? const Color(0xFFB9ED54),
      form: artwork?.form ?? ProductForm.pouch,
      flavors: artwork?.flavors ?? const [],
      imageUrl: artwork?.imageUrl,
    );
  }

  OrderStatus _status(String value) => switch (value.toUpperCase()) {
    'PLACED' || 'PENDING' => OrderStatus.pending,
    'CONFIRMED' => OrderStatus.confirmed,
    'PREPARING' => OrderStatus.preparing,
    'READY_FOR_PICKUP' => OrderStatus.readyForPickup,
    'PICKED_UP' => OrderStatus.pickedUp,
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

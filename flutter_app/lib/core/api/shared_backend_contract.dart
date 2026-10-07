import 'api_models.dart';
import 'money_codec.dart';

/// Maps the Day 8 Prisma foundation's field names to Proto-facing wire DTOs.
/// This is schema alignment, not a claim that commerce endpoints exist yet.
class SharedBackendContract {
  const SharedBackendContract._();

  static CustomerDto customer(JsonMap json) => CustomerDto.fromJson(json);
  static CategoryDto category(JsonMap json) => CategoryDto.fromJson(json);

  static ProductDto product(JsonMap json) => ProductDto(
    id: json['id'] as String,
    categoryId: json['categoryId'] as String,
    name: json['name'] as String,
    description: json['description'] as String? ?? '',
    pricePaise: MoneyCodec.paiseFromRupees(json['price']!),
    available: json['isActive'] as bool? ?? true,
    sku: json['sku'] as String?,
    currency: json['currency'] as String? ?? 'INR',
  );

  static AddressDto address(JsonMap json) => AddressDto(
    id: json['id'] as String,
    label: json['label'] as String,
    line1: json['line1'] as String,
    area: json['area'] as String? ?? json['line2'] as String? ?? '',
    city: json['city'] as String,
    postalCode: json['postalCode'] as String? ?? '',
    line2: json['line2'] as String?,
    recipientName: json['recipientName'] as String?,
    phone: json['phone'] as String?,
    userId: json['userId'] as String?,
    isDefault: json['isDefault'] as bool?,
  );

  static OrderItemDto orderItem(JsonMap json) => OrderItemDto(
    id: json['id'] as String?,
    productId: json['productId'] as String,
    name: json['productName'] as String,
    quantity: json['quantity'] as int,
    unitPricePaise: MoneyCodec.paiseFromRupees(json['unitPrice']!),
    lineTotalPaise: MoneyCodec.paiseFromRupees(json['lineTotal']!),
  );

  static PaymentDto payment(JsonMap json) => PaymentDto(
    id: json['id'] as String?,
    method: json['method'] as String,
    status: json['status'] as String,
    amountPaise: MoneyCodec.paiseFromRupees(json['amount']!),
    currency: json['currency'] as String? ?? 'INR',
    reference: json['providerReference'] as String?,
    paidAt: json['paidAt'] == null
        ? null
        : DateTime.parse(json['paidAt'] as String),
  );

  static DriverAssignmentDto? assignment(JsonMap job) {
    final driver = job['driver'];
    if (driver is! Map) return null;
    final vehicle = job['vehicle'];
    final vehicleMap = vehicle is Map ? vehicle : const {};
    return DriverAssignmentDto(
      deliveryJobId: job['id'] as String,
      driverName: driver['name'] as String,
      vehicle: [
        vehicleMap['vehicleType'],
        vehicleMap['registrationNumber'],
      ].whereType<String>().join(' · '),
      contact: driver['phone'] as String?,
      eta: job['estimatedDeliveryAt'] == null
          ? null
          : DateTime.parse(job['estimatedDeliveryAt'] as String),
    );
  }

  static DeliveryJobDto delivery(JsonMap json) => DeliveryJobDto(
    id: json['id'] as String,
    orderId: json['orderId'] as String,
    status: json['status'] as String,
    estimatedMinutes: json['estimatedMinutes'] as int?,
    assignment: assignment(json),
  );

  /// Expects expanded `items`; nullable address, payment, and deliveryJob
  /// match the Prisma relations. The eventual API must define its own response.
  static OrderDto order(JsonMap json) {
    final rawItems = json['items'] as List;
    final job = json['deliveryJob'];
    final deliveryJob = job is Map ? Map<String, dynamic>.from(job) : null;
    return OrderDto(
      id: json['id'] as String,
      reference: json['reference'] as String?,
      customerId: json['customerId'] as String?,
      customer: json['customer'] is Map
          ? customer(Map<String, dynamic>.from(json['customer'] as Map))
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      status: json['status'] as String,
      estimatedDeliveryAt: json['estimatedDeliveryAt'] == null
          ? null
          : DateTime.parse(json['estimatedDeliveryAt'] as String),
      items: rawItems
          .map((item) => orderItem(Map<String, dynamic>.from(item as Map)))
          .toList(),
      address: json['deliveryAddress'] is Map
          ? address(Map<String, dynamic>.from(json['deliveryAddress'] as Map))
          : null,
      payment: json['payment'] is Map
          ? payment(Map<String, dynamic>.from(json['payment'] as Map))
          : null,
      subtotalPaise: MoneyCodec.paiseFromRupees(json['subtotal']!),
      deliveryFeePaise: MoneyCodec.paiseFromRupees(json['deliveryFee']!),
      discountPaise: json['discount'] == null
          ? 0
          : MoneyCodec.paiseFromRupees(json['discount']!),
      totalPaise: MoneyCodec.paiseFromRupees(json['total']!),
      delivery: deliveryJob == null ? null : delivery(deliveryJob),
      driver: deliveryJob == null ? null : assignment(deliveryJob),
    );
  }
}

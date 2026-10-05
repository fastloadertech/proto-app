/// Wire contracts only. UI artwork, widget colors, and local state do not
/// belong in API payloads. All monetary values are integer INR paise.
typedef JsonMap = Map<String, dynamic>;

String _string(JsonMap json, String key) => json[key] as String;
int _int(JsonMap json, String key) => json[key] as int;
JsonMap _object(JsonMap json, String key) =>
    Map<String, dynamic>.from(json[key] as Map);
List<JsonMap> _objects(JsonMap json, String key) => (json[key] as List)
    .map((value) => Map<String, dynamic>.from(value as Map))
    .toList();

class CustomerDto {
  const CustomerDto({
    required this.id,
    required this.name,
    required this.phone,
    this.email,
  });
  final String id, name, phone;
  final String? email;
  factory CustomerDto.fromJson(JsonMap json) => CustomerDto(
    id: _string(json, 'id'),
    name: _string(json, 'name'),
    phone: _string(json, 'phone'),
    email: json['email'] as String?,
  );
  JsonMap toJson() => {
    'id': id,
    'name': name,
    'phone': phone,
    if (email != null) 'email': email,
  };
}

/// The access token is in-memory only. Never put it in order/customer DTOs.
class AuthSessionDto {
  const AuthSessionDto({
    required this.customer,
    required this.accessToken,
    required this.expiresAt,
  });
  final CustomerDto customer;
  final String accessToken;
  final DateTime expiresAt;
  factory AuthSessionDto.fromJson(JsonMap json) => AuthSessionDto(
    customer: CustomerDto.fromJson(_object(json, 'customer')),
    accessToken: _string(json, 'accessToken'),
    expiresAt: DateTime.parse(_string(json, 'expiresAt')),
  );
  JsonMap toJson() => {
    'customer': customer.toJson(),
    'accessToken': accessToken,
    'expiresAt': expiresAt.toUtc().toIso8601String(),
  };
}

class CategoryDto {
  const CategoryDto({
    required this.id,
    required this.name,
    this.slug,
    this.description,
    this.isActive,
  });
  final String id, name;
  final String? slug, description;
  final bool? isActive;
  factory CategoryDto.fromJson(JsonMap json) => CategoryDto(
    id: _string(json, 'id'),
    name: _string(json, 'name'),
    slug: json['slug'] as String?,
    description: json['description'] as String?,
    isActive: json['isActive'] as bool?,
  );
  JsonMap toJson() => {
    'id': id,
    'name': name,
    if (slug != null) 'slug': slug,
    if (description != null) 'description': description,
    if (isActive != null) 'isActive': isActive,
  };
}

class ProductDto {
  const ProductDto({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.description,
    required this.pricePaise,
    required this.available,
    this.imageUrl,
    this.type,
    this.flavors = const [],
    this.sku,
    this.currency = 'INR',
  });
  final String id, categoryId, name, description;
  final int pricePaise;
  final bool available;
  final String? imageUrl, type;
  final String? sku;
  final String currency;
  final List<String> flavors;
  factory ProductDto.fromJson(JsonMap json) => ProductDto(
    id: _string(json, 'id'),
    categoryId: _string(json, 'categoryId'),
    name: _string(json, 'name'),
    description: _string(json, 'description'),
    pricePaise: _int(json, 'pricePaise'),
    available: json['available'] as bool,
    imageUrl: json['imageUrl'] as String?,
    type: json['type'] as String?,
    flavors: List<String>.from(json['flavors'] as List? ?? const []),
    sku: json['sku'] as String?,
    currency: json['currency'] as String? ?? 'INR',
  );
  JsonMap toJson() => {
    'id': id,
    'categoryId': categoryId,
    'name': name,
    'description': description,
    'pricePaise': pricePaise,
    'available': available,
    if (imageUrl != null) 'imageUrl': imageUrl,
    if (type != null) 'type': type,
    'flavors': flavors,
    if (sku != null) 'sku': sku,
    'currency': currency,
  };
}

class AddressDto {
  const AddressDto({
    required this.id,
    required this.label,
    required this.line1,
    required this.area,
    required this.city,
    required this.postalCode,
    this.line2,
    this.recipientName,
    this.phone,
    this.userId,
    this.isDefault,
  });
  final String id, label, line1, area, city, postalCode;
  final String? line2, recipientName, phone, userId;
  final bool? isDefault;
  factory AddressDto.fromJson(JsonMap json) => AddressDto(
    id: _string(json, 'id'),
    label: _string(json, 'label'),
    line1: _string(json, 'line1'),
    area: _string(json, 'area'),
    city: _string(json, 'city'),
    postalCode: _string(json, 'postalCode'),
    line2: json['line2'] as String?,
    recipientName: json['recipientName'] as String?,
    phone: json['phone'] as String?,
    userId: json['userId'] as String?,
    isDefault: json['isDefault'] as bool?,
  );
  JsonMap toJson() => {
    'id': id,
    'label': label,
    'line1': line1,
    'area': area,
    'city': city,
    'postalCode': postalCode,
    if (line2 != null) 'line2': line2,
    if (recipientName != null) 'recipientName': recipientName,
    if (phone != null) 'phone': phone,
    if (userId != null) 'userId': userId,
    if (isDefault != null) 'isDefault': isDefault,
  };
}

class OrderItemDto {
  const OrderItemDto({
    required this.productId,
    required this.name,
    required this.quantity,
    required this.unitPricePaise,
    this.flavor,
    this.id,
    this.lineTotalPaise,
  });
  final String productId, name;
  final int quantity, unitPricePaise;
  final String? flavor;
  final String? id;
  final int? lineTotalPaise;
  factory OrderItemDto.fromJson(JsonMap json) => OrderItemDto(
    productId: _string(json, 'productId'),
    name: _string(json, 'name'),
    quantity: _int(json, 'quantity'),
    unitPricePaise: _int(json, 'unitPricePaise'),
    flavor: json['flavor'] as String?,
    id: json['id'] as String?,
    lineTotalPaise: json['lineTotalPaise'] as int?,
  );
  JsonMap toJson() => {
    'productId': productId,
    'name': name,
    'quantity': quantity,
    'unitPricePaise': unitPricePaise,
    if (flavor != null) 'flavor': flavor,
    if (id != null) 'id': id,
    if (lineTotalPaise != null) 'lineTotalPaise': lineTotalPaise,
  };
}

class PaymentDto {
  const PaymentDto({
    required this.method,
    required this.status,
    this.reference,
    this.id,
    this.amountPaise,
    this.currency = 'INR',
    this.paidAt,
  });

  /// Examples: cash_on_delivery, upi, card; not_charged, pending, paid.
  final String method, status;
  final String? reference;
  final String? id;
  final int? amountPaise;
  final String currency;
  final DateTime? paidAt;
  factory PaymentDto.fromJson(JsonMap json) => PaymentDto(
    method: _string(json, 'method'),
    status: _string(json, 'status'),
    reference: json['reference'] as String?,
    id: json['id'] as String?,
    amountPaise: json['amountPaise'] as int?,
    currency: json['currency'] as String? ?? 'INR',
    paidAt: json['paidAt'] == null
        ? null
        : DateTime.parse(_string(json, 'paidAt')),
  );
  JsonMap toJson() => {
    'method': method,
    'status': status,
    if (reference != null) 'reference': reference,
    if (id != null) 'id': id,
    if (amountPaise != null) 'amountPaise': amountPaise,
    'currency': currency,
    if (paidAt != null) 'paidAt': paidAt!.toUtc().toIso8601String(),
  };
}

class DriverAssignmentDto {
  const DriverAssignmentDto({
    required this.deliveryJobId,
    required this.driverName,
    required this.vehicle,
    this.contact,
    this.eta,
  });
  final String deliveryJobId, driverName, vehicle;
  final String? contact;
  final DateTime? eta;
  factory DriverAssignmentDto.fromJson(JsonMap json) => DriverAssignmentDto(
    deliveryJobId: _string(json, 'deliveryJobId'),
    driverName: _string(json, 'driverName'),
    vehicle: _string(json, 'vehicle'),
    contact: json['contact'] as String?,
    eta: json['eta'] == null ? null : DateTime.parse(_string(json, 'eta')),
  );
  JsonMap toJson() => {
    'deliveryJobId': deliveryJobId,
    'driverName': driverName,
    'vehicle': vehicle,
    if (contact != null) 'contact': contact,
    if (eta != null) 'eta': eta!.toUtc().toIso8601String(),
  };
}

/// Customer-facing snapshot of the shared backend's DeliveryJob. The legacy
/// Loader Delivery record is a different entity and never appears here.
class DeliveryJobDto {
  const DeliveryJobDto({
    required this.id,
    required this.orderId,
    required this.status,
    this.estimatedMinutes,
    this.assignment,
  });
  final String id, orderId, status;
  final int? estimatedMinutes;
  final DriverAssignmentDto? assignment;
  factory DeliveryJobDto.fromJson(JsonMap json) => DeliveryJobDto(
    id: _string(json, 'id'),
    orderId: _string(json, 'orderId'),
    status: _string(json, 'status'),
    estimatedMinutes: json['estimatedMinutes'] as int?,
    assignment: json['assignment'] == null
        ? null
        : DriverAssignmentDto.fromJson(_object(json, 'assignment')),
  );
  JsonMap toJson() => {
    'id': id,
    'orderId': orderId,
    'status': status,
    if (estimatedMinutes != null) 'estimatedMinutes': estimatedMinutes,
    if (assignment != null) 'assignment': assignment!.toJson(),
  };
}

class OrderDto {
  const OrderDto({
    required this.id,
    required this.createdAt,
    required this.status,
    required this.items,
    this.address,
    this.payment,
    required this.subtotalPaise,
    required this.deliveryFeePaise,
    required this.discountPaise,
    required this.totalPaise,
    this.estimatedDeliveryAt,
    this.driver,
    this.reference,
    this.customerId,
    this.customer,
    this.delivery,
  });
  final String id, status;
  final String? reference, customerId;
  final CustomerDto? customer;
  final DateTime createdAt;
  final DateTime? estimatedDeliveryAt;
  final List<OrderItemDto> items;
  final AddressDto? address;
  final PaymentDto? payment;
  final int subtotalPaise, deliveryFeePaise, discountPaise, totalPaise;
  final DriverAssignmentDto? driver;
  final DeliveryJobDto? delivery;
  factory OrderDto.fromJson(JsonMap json) => OrderDto(
    id: _string(json, 'id'),
    createdAt: DateTime.parse(_string(json, 'createdAt')),
    status: _string(json, 'status'),
    items: _objects(json, 'items').map(OrderItemDto.fromJson).toList(),
    address: json['address'] == null
        ? null
        : AddressDto.fromJson(_object(json, 'address')),
    payment: json['payment'] == null
        ? null
        : PaymentDto.fromJson(_object(json, 'payment')),
    subtotalPaise: _int(json, 'subtotalPaise'),
    deliveryFeePaise: _int(json, 'deliveryFeePaise'),
    discountPaise: _int(json, 'discountPaise'),
    totalPaise: _int(json, 'totalPaise'),
    estimatedDeliveryAt: json['estimatedDeliveryAt'] == null
        ? null
        : DateTime.parse(_string(json, 'estimatedDeliveryAt')),
    driver: json['driver'] == null
        ? null
        : DriverAssignmentDto.fromJson(_object(json, 'driver')),
    reference: json['reference'] as String?,
    customerId: json['customerId'] as String?,
    customer: json['customer'] == null
        ? null
        : CustomerDto.fromJson(_object(json, 'customer')),
    delivery: json['delivery'] == null
        ? null
        : DeliveryJobDto.fromJson(_object(json, 'delivery')),
  );
  JsonMap toJson() => {
    'id': id,
    'createdAt': createdAt.toUtc().toIso8601String(),
    'status': status,
    'items': items.map((item) => item.toJson()).toList(),
    if (address != null) 'address': address!.toJson(),
    if (payment != null) 'payment': payment!.toJson(),
    'subtotalPaise': subtotalPaise,
    'deliveryFeePaise': deliveryFeePaise,
    'discountPaise': discountPaise,
    'totalPaise': totalPaise,
    if (estimatedDeliveryAt != null)
      'estimatedDeliveryAt': estimatedDeliveryAt!.toUtc().toIso8601String(),
    if (driver != null) 'driver': driver!.toJson(),
    if (reference != null) 'reference': reference,
    if (customerId != null) 'customerId': customerId,
    if (customer != null) 'customer': customer!.toJson(),
    if (delivery != null) 'delivery': delivery!.toJson(),
  };
}

/// Request sends IDs and customer choices; server calculates and returns totals.
class CreateOrderRequestDto {
  const CreateOrderRequestDto({
    required this.addressId,
    required this.paymentMethod,
    required this.items,
    this.promoCode,
  });
  final String addressId, paymentMethod;
  final String? promoCode;
  final List<CreateOrderLineDto> items;
  factory CreateOrderRequestDto.fromJson(JsonMap json) => CreateOrderRequestDto(
    addressId: _string(json, 'addressId'),
    paymentMethod: _string(json, 'paymentMethod'),
    items: _objects(json, 'items').map(CreateOrderLineDto.fromJson).toList(),
    promoCode: json['promoCode'] as String?,
  );
  JsonMap toJson() => {
    'addressId': addressId,
    'paymentMethod': paymentMethod,
    'items': items.map((item) => item.toJson()).toList(),
    if (promoCode != null) 'promoCode': promoCode,
  };
}

class CreateOrderLineDto {
  const CreateOrderLineDto({
    required this.productId,
    required this.quantity,
    this.flavor,
  });
  final String productId;
  final int quantity;
  final String? flavor;
  factory CreateOrderLineDto.fromJson(JsonMap json) => CreateOrderLineDto(
    productId: _string(json, 'productId'),
    quantity: _int(json, 'quantity'),
    flavor: json['flavor'] as String?,
  );
  JsonMap toJson() => {
    'productId': productId,
    'quantity': quantity,
    if (flavor != null) 'flavor': flavor,
  };
}

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
  const CategoryDto({required this.id, required this.name});
  final String id, name;
  factory CategoryDto.fromJson(JsonMap json) =>
      CategoryDto(id: _string(json, 'id'), name: _string(json, 'name'));
  JsonMap toJson() => {'id': id, 'name': name};
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
  });
  final String id, categoryId, name, description;
  final int pricePaise;
  final bool available;
  final String? imageUrl, type;
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
  });
  final String id, label, line1, area, city, postalCode;
  factory AddressDto.fromJson(JsonMap json) => AddressDto(
    id: _string(json, 'id'),
    label: _string(json, 'label'),
    line1: _string(json, 'line1'),
    area: _string(json, 'area'),
    city: _string(json, 'city'),
    postalCode: _string(json, 'postalCode'),
  );
  JsonMap toJson() => {
    'id': id,
    'label': label,
    'line1': line1,
    'area': area,
    'city': city,
    'postalCode': postalCode,
  };
}

class OrderItemDto {
  const OrderItemDto({
    required this.productId,
    required this.name,
    required this.quantity,
    required this.unitPricePaise,
    this.flavor,
  });
  final String productId, name;
  final int quantity, unitPricePaise;
  final String? flavor;
  factory OrderItemDto.fromJson(JsonMap json) => OrderItemDto(
    productId: _string(json, 'productId'),
    name: _string(json, 'name'),
    quantity: _int(json, 'quantity'),
    unitPricePaise: _int(json, 'unitPricePaise'),
    flavor: json['flavor'] as String?,
  );
  JsonMap toJson() => {
    'productId': productId,
    'name': name,
    'quantity': quantity,
    'unitPricePaise': unitPricePaise,
    if (flavor != null) 'flavor': flavor,
  };
}

class PaymentDto {
  const PaymentDto({
    required this.method,
    required this.status,
    this.reference,
  });

  /// Examples: cash_on_delivery, upi, card; not_charged, pending, paid.
  final String method, status;
  final String? reference;
  factory PaymentDto.fromJson(JsonMap json) => PaymentDto(
    method: _string(json, 'method'),
    status: _string(json, 'status'),
    reference: json['reference'] as String?,
  );
  JsonMap toJson() => {
    'method': method,
    'status': status,
    if (reference != null) 'reference': reference,
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

class OrderDto {
  const OrderDto({
    required this.id,
    required this.createdAt,
    required this.status,
    required this.items,
    required this.address,
    required this.payment,
    required this.subtotalPaise,
    required this.deliveryFeePaise,
    required this.discountPaise,
    required this.totalPaise,
    this.estimatedDeliveryAt,
    this.driver,
  });
  final String id, status;
  final DateTime createdAt;
  final DateTime? estimatedDeliveryAt;
  final List<OrderItemDto> items;
  final AddressDto address;
  final PaymentDto payment;
  final int subtotalPaise, deliveryFeePaise, discountPaise, totalPaise;
  final DriverAssignmentDto? driver;
  factory OrderDto.fromJson(JsonMap json) => OrderDto(
    id: _string(json, 'id'),
    createdAt: DateTime.parse(_string(json, 'createdAt')),
    status: _string(json, 'status'),
    items: _objects(json, 'items').map(OrderItemDto.fromJson).toList(),
    address: AddressDto.fromJson(_object(json, 'address')),
    payment: PaymentDto.fromJson(_object(json, 'payment')),
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
  );
  JsonMap toJson() => {
    'id': id,
    'createdAt': createdAt.toUtc().toIso8601String(),
    'status': status,
    'items': items.map((item) => item.toJson()).toList(),
    'address': address.toJson(),
    'payment': payment.toJson(),
    'subtotalPaise': subtotalPaise,
    'deliveryFeePaise': deliveryFeePaise,
    'discountPaise': discountPaise,
    'totalPaise': totalPaise,
    if (estimatedDeliveryAt != null)
      'estimatedDeliveryAt': estimatedDeliveryAt!.toUtc().toIso8601String(),
    if (driver != null) 'driver': driver!.toJson(),
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

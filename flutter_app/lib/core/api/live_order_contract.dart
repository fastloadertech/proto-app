import 'money_codec.dart';

class CreateLiveOrderRequestDto {
  const CreateLiveOrderRequestDto({required this.items, required this.address});
  final List<CreateLiveOrderItemDto> items;
  final LiveOrderAddressDto address;

  Map<String, dynamic> toJson() => {
    'items': items.map((item) => item.toJson()).toList(),
    'deliveryAddress': address.toJson(),
  };
}

class CreateLiveOrderItemDto {
  const CreateLiveOrderItemDto({
    required this.productId,
    required this.quantity,
  });
  final String productId;
  final int quantity;

  Map<String, dynamic> toJson() => {
    'productId': productId,
    'quantity': quantity,
  };
}

/// The implemented Day 11 order response. Kept separate from the earlier
/// proposed OrderDto so local/demo and older contract tests stay compatible.
class LiveOrderDto {
  const LiveOrderDto({
    required this.id,
    required this.reference,
    required this.status,
    required this.subtotalPaise,
    required this.deliveryFeePaise,
    required this.totalPaise,
    required this.currency,
    required this.address,
    required this.items,
    required this.createdAt,
    required this.updatedAt,
    this.delivery,
  });

  final String id, reference, status, currency;
  final int subtotalPaise, deliveryFeePaise, totalPaise;
  final LiveOrderAddressDto address;
  final List<LiveOrderItemDto> items;
  final DateTime createdAt, updatedAt;
  final LiveDeliveryLinkDto? delivery;

  factory LiveOrderDto.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    if (rawItems is! List || rawItems.isEmpty) {
      throw const FormatException('Order items are missing.');
    }
    final items = rawItems
        .map((item) {
          if (item is! Map) throw const FormatException('Invalid order item.');
          return LiveOrderItemDto.fromJson(Map<String, dynamic>.from(item));
        })
        .toList(growable: false);
    final subtotal = MoneyCodec.paiseFromRupees(json['subtotal']!);
    final fee = MoneyCodec.paiseFromRupees(json['deliveryFee']!);
    final total = MoneyCodec.paiseFromRupees(json['total']!);
    if (items.fold<int>(0, (sum, item) => sum + item.lineTotalPaise) !=
            subtotal ||
        subtotal + fee != total) {
      throw const FormatException('Order totals do not match.');
    }
    final rawAddress = json['deliveryAddress'];
    if (rawAddress is! Map) {
      throw const FormatException('Delivery address is missing.');
    }
    return LiveOrderDto(
      id: _requiredString(json, 'id'),
      reference: _requiredString(json, 'reference'),
      status: _requiredString(json, 'status'),
      subtotalPaise: subtotal,
      deliveryFeePaise: fee,
      totalPaise: total,
      currency: _requiredString(json, 'currency'),
      address: LiveOrderAddressDto.fromJson(
        Map<String, dynamic>.from(rawAddress),
      ),
      items: items,
      createdAt: _date(json, 'createdAt'),
      updatedAt: _date(json, 'updatedAt'),
      delivery: json['delivery'] == null
          ? null
          : LiveDeliveryLinkDto.fromJson(
              Map<String, dynamic>.from(json['delivery'] as Map),
            ),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'reference': reference,
    'status': status,
    'subtotal': MoneyCodec.rupeesFromPaise(subtotalPaise),
    'deliveryFee': MoneyCodec.rupeesFromPaise(deliveryFeePaise),
    'total': MoneyCodec.rupeesFromPaise(totalPaise),
    'currency': currency,
    'deliveryAddress': address.toJson(),
    'items': items.map((item) => item.toJson()).toList(),
    'createdAt': createdAt.toUtc().toIso8601String(),
    'updatedAt': updatedAt.toUtc().toIso8601String(),
    if (delivery != null) 'delivery': delivery!.toJson(),
  };
}

/// GET /orders/:id includes this link; GET /orders and POST /orders do not.
class LiveDeliveryLinkDto {
  const LiveDeliveryLinkDto({required this.id, required this.status});
  final String id, status;

  factory LiveDeliveryLinkDto.fromJson(Map<String, dynamic> json) =>
      LiveDeliveryLinkDto(
        id: _requiredString(json, 'id'),
        status: _requiredString(json, 'status'),
      );

  Map<String, dynamic> toJson() => {'id': id, 'status': status};
}

class LiveOrderItemDto {
  const LiveOrderItemDto({
    required this.id,
    required this.productId,
    required this.productName,
    required this.unitPricePaise,
    required this.quantity,
    required this.lineTotalPaise,
  });
  final String id, productId, productName;
  final int unitPricePaise, quantity, lineTotalPaise;

  factory LiveOrderItemDto.fromJson(Map<String, dynamic> json) {
    final quantity = json['quantity'];
    if (quantity is! int || quantity <= 0) {
      throw const FormatException('Invalid order quantity.');
    }
    final unit = MoneyCodec.paiseFromRupees(json['unitPrice']!);
    final line = MoneyCodec.paiseFromRupees(json['lineTotal']!);
    if (unit * quantity != line) {
      throw const FormatException('Order line total does not match.');
    }
    return LiveOrderItemDto(
      id: _requiredString(json, 'id'),
      productId: _requiredString(json, 'productId'),
      productName: _requiredString(json, 'productName'),
      unitPricePaise: unit,
      quantity: quantity,
      lineTotalPaise: line,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'productId': productId,
    'productName': productName,
    'unitPrice': MoneyCodec.rupeesFromPaise(unitPricePaise),
    'quantity': quantity,
    'lineTotal': MoneyCodec.rupeesFromPaise(lineTotalPaise),
  };
}

class LiveOrderAddressDto {
  const LiveOrderAddressDto({
    required this.line1,
    required this.city,
    this.line2,
    this.state,
    this.postalCode,
    this.recipientName,
    this.phone,
  });
  final String line1, city;
  final String? line2, state, postalCode, recipientName, phone;

  factory LiveOrderAddressDto.fromJson(Map<String, dynamic> json) =>
      LiveOrderAddressDto(
        line1: _requiredString(json, 'line1'),
        line2: _optionalString(json, 'line2'),
        city: _requiredString(json, 'city'),
        state: _optionalString(json, 'state'),
        postalCode: _optionalString(json, 'postalCode'),
        recipientName: _optionalString(json, 'recipientName'),
        phone: _optionalString(json, 'phone'),
      );

  Map<String, dynamic> toJson() => {
    'line1': line1,
    'line2': line2,
    'city': city,
    'state': state,
    'postalCode': postalCode,
    'recipientName': recipientName,
    'phone': phone,
  };
}

String _requiredString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! String || value.trim().isEmpty) {
    throw FormatException('Missing $key.');
  }
  return value;
}

String? _optionalString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value == null) return null;
  if (value is! String) throw FormatException('Invalid $key.');
  return value;
}

DateTime _date(Map<String, dynamic> json, String key) {
  final value = _requiredString(json, key);
  final parsed = DateTime.tryParse(value);
  if (parsed == null) throw FormatException('Invalid $key.');
  return parsed;
}

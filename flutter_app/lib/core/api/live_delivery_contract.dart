/// Read-only customer subset of GET /api/v1/deliveries/:id.
class LiveDeliveryDto {
  const LiveDeliveryDto({
    required this.id,
    required this.orderId,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.driverId,
    this.assignedAt,
    this.acceptedAt,
    this.pickedUpAt,
    this.deliveredAt,
  });

  final String id, orderId, status;
  final String? driverId;
  final DateTime createdAt, updatedAt;
  final DateTime? assignedAt, acceptedAt, pickedUpAt, deliveredAt;

  factory LiveDeliveryDto.fromJson(Map<String, dynamic> json) =>
      LiveDeliveryDto(
        id: _string(json, 'id'),
        orderId: _string(json, 'orderId'),
        status: _string(json, 'status'),
        driverId: _optionalString(json, 'driverId'),
        createdAt: _date(json, 'createdAt'),
        updatedAt: _date(json, 'updatedAt'),
        assignedAt: _optionalDate(json, 'assignedAt'),
        acceptedAt: _optionalDate(json, 'acceptedAt'),
        pickedUpAt: _optionalDate(json, 'pickedUpAt'),
        deliveredAt: _optionalDate(json, 'deliveredAt'),
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'orderId': orderId,
    'status': status,
    'driverId': driverId,
    'createdAt': createdAt.toUtc().toIso8601String(),
    'updatedAt': updatedAt.toUtc().toIso8601String(),
    'assignedAt': assignedAt?.toUtc().toIso8601String(),
    'acceptedAt': acceptedAt?.toUtc().toIso8601String(),
    'pickedUpAt': pickedUpAt?.toUtc().toIso8601String(),
    'deliveredAt': deliveredAt?.toUtc().toIso8601String(),
  };
}

String _string(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! String || value.trim().isEmpty) {
    throw FormatException('Invalid $key.');
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
  final value = DateTime.tryParse(_string(json, key));
  if (value == null) throw FormatException('Invalid $key.');
  return value;
}

DateTime? _optionalDate(Map<String, dynamic> json, String key) =>
    json[key] == null ? null : _date(json, key);

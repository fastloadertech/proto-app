/// Customer-visible delivery data. It is separate from order status because
/// the backend does not advance the order when a driver accepts a job.
enum DeliveryStatus {
  requested,
  available,
  driverAssigned,
  driverArriving,
  arrivedAtPickup,
  accepted,
  pickedUp,
  onTheWay,
  inTransit,
  outForDelivery,
  delivered,
  cancelled;

  static const day12Stages = [
    available,
    accepted,
    pickedUp,
    outForDelivery,
    delivered,
  ];

  String get label => switch (this) {
    requested => 'Requested',
    available => 'Awaiting a delivery partner',
    driverAssigned => 'Driver assigned',
    driverArriving => 'Driver arriving',
    arrivedAtPickup => 'Driver at pickup',
    accepted => 'Accepted',
    pickedUp => 'Picked up',
    onTheWay => 'On the way',
    inTransit => 'In transit',
    outForDelivery => 'Out for delivery',
    delivered => 'Delivered',
    cancelled => 'Cancelled',
  };

  String get description => switch (this) {
    requested => 'The delivery request has been created.',
    available => 'A delivery partner has not accepted this job yet.',
    driverAssigned => 'A delivery partner has been assigned.',
    driverArriving => 'The delivery partner is heading to pickup.',
    arrivedAtPickup => 'The delivery partner reached pickup.',
    accepted => 'A delivery partner accepted the job.',
    pickedUp => 'Your order was picked up.',
    onTheWay => 'Your order is on the way.',
    inTransit => 'Your order is in transit.',
    outForDelivery => 'Your order is out for delivery.',
    delivered => 'The delivery was marked delivered.',
    cancelled => 'The delivery was cancelled.',
  };
}

enum DeliveryIssue { authentication, missing, network, server, invalid }

class DeliverySnapshot {
  const DeliverySnapshot({
    required this.id,
    required this.orderId,
    required this.status,
    this.updatedAt,
    this.acceptedAt,
    this.pickedUpAt,
    this.deliveredAt,
    this.hasDetails = false,
  });

  final String id, orderId;
  final DeliveryStatus status;
  final DateTime? updatedAt, acceptedAt, pickedUpAt, deliveredAt;
  final bool hasDetails;
}

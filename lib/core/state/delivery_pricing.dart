abstract final class DeliveryPricing {
  static const double freeDeliveryThreshold = 499;
  static const double standardFee = 35;

  static double feeFor(double subtotal) =>
      subtotal <= 0 || subtotal >= freeDeliveryThreshold ? 0 : standardFee;
}

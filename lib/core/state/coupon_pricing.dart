/// Deterministic, local-only promotion rules for the Proto demo.
enum CouponStatus { applied, invalid, expired, minimumNotMet, emptyBag }

class CouponEvaluation {
  const CouponEvaluation({
    required this.code,
    required this.status,
    this.discount = 0,
  });

  final String code;
  final CouponStatus status;
  final double discount;

  bool get isApplied => status == CouponStatus.applied;

  String get message => switch (status) {
    CouponStatus.applied => '$code applied.',
    CouponStatus.invalid => 'This coupon code is not available.',
    CouponStatus.expired => 'This coupon has expired.',
    CouponStatus.minimumNotMet =>
      'FUEL50 needs a bag subtotal of at least ₹499.',
    CouponStatus.emptyBag => 'Add products to your bag before using a coupon.',
  };
}

abstract final class CouponPricing {
  static const double _fuel50Minimum = 499;
  static const double _proto10Cap = 250;

  static CouponEvaluation evaluate(String input, double subtotal) {
    final code = input.trim().toUpperCase();
    if (subtotal <= 0) {
      return CouponEvaluation(code: code, status: CouponStatus.emptyBag);
    }
    if (code == 'EXPIRED') {
      return CouponEvaluation(code: code, status: CouponStatus.expired);
    }
    if (code == 'PROTO10') {
      final rawDiscount = (subtotal * .10).roundToDouble();
      return CouponEvaluation(
        code: code,
        status: CouponStatus.applied,
        discount: rawDiscount > _proto10Cap ? _proto10Cap : rawDiscount,
      );
    }
    if (code == 'FUEL50') {
      if (subtotal < _fuel50Minimum) {
        return CouponEvaluation(code: code, status: CouponStatus.minimumNotMet);
      }
      return const CouponEvaluation(
        code: 'FUEL50',
        status: CouponStatus.applied,
        discount: 50,
      );
    }
    return CouponEvaluation(code: code, status: CouponStatus.invalid);
  }
}

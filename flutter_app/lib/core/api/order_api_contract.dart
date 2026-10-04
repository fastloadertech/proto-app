/// Proposed Proto customer endpoints. These are route definitions only.
/// No HTTP client or backend implementation is included in Day 7.
class OrderApiContract {
  const OrderApiContract._();
  static const ordersPath = '/v1/customer/orders';
  static String orderPath(String id) =>
      '$ordersPath/${Uri.encodeComponent(id)}';
  static String cancelPath(String id) => '${orderPath(id)}/cancel';
  static String statusPath(String id) => '${orderPath(id)}/status';
}

/// Shared NestJS customer routes under the /api/v1 prefix.
class ApiRoutes {
  const ApiRoutes._();
  static const authLogin = '/api/v1/auth/customer/login';
  static const authMe = '/api/v1/auth/me';
  static const categories = '/api/v1/catalog/categories';
  static const products = '/api/v1/catalog/products';
  static String product(String id) => '$products/${Uri.encodeComponent(id)}';
  static const orders = '/api/v1/orders';
  static String order(String id) => '$orders/${Uri.encodeComponent(id)}';
  static String delivery(String id) =>
      '/api/v1/deliveries/${Uri.encodeComponent(id)}';
  static String orderStatus(String id) => '${order(id)}/status';
  static String cancelOrder(String id) => '${order(id)}/cancel';
}

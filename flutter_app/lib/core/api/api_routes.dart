/// Proposed commerce routes under the shared NestJS /api/v1 prefix.
/// The Day 8 backend has module boundaries, not commerce controllers yet.
class ApiRoutes {
  const ApiRoutes._();
  static const authLogin = '/api/v1/customer/auth/login';
  static const authLogout = '/api/v1/customer/auth/logout';
  static const authMe = '/api/v1/customer/auth/me';
  static const categories = '/api/v1/catalog/categories';
  static const products = '/api/v1/catalog/products';
  static const orders = '/api/v1/customer/orders';
  static String order(String id) => '$orders/${Uri.encodeComponent(id)}';
  static String orderStatus(String id) => '${order(id)}/status';
  static String cancelOrder(String id) => '${order(id)}/cancel';
}

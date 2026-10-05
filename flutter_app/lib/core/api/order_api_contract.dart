import 'api_routes.dart';

/// Backward-compatible names for proposed shared-backend order routes.
class OrderApiContract {
  const OrderApiContract._();
  static const ordersPath = ApiRoutes.orders;
  static String orderPath(String id) => ApiRoutes.order(id);
  static String cancelPath(String id) => ApiRoutes.cancelOrder(id);
  static String statusPath(String id) => ApiRoutes.orderStatus(id);
}

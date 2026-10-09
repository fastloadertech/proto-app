/// API configuration is inert until an API repository is explicitly injected.
/// The production URL is deliberately unset; no secret belongs in dart-define.
enum ApiEnvironment { development, production }

class ApiConfig {
  const ApiConfig({
    this.environment = ApiEnvironment.development,
    this.developmentBaseUrl = defaultDevelopmentBaseUrl,
    this.productionBaseUrl = defaultProductionBaseUrl,
  });

  static const defaultDevelopmentBaseUrl = String.fromEnvironment(
    'PROTO_API_BASE_URL',
    defaultValue: 'http://localhost:3101',
  );

  /// Opt in at launch with --dart-define=PROTO_LIVE_AUTH=true.
  static const liveCustomerAuth = bool.fromEnvironment(
    'PROTO_LIVE_AUTH',
    defaultValue: false,
  );

  /// Explicit Day 10 catalog opt-in; local catalog remains the default.
  static const liveCatalog = bool.fromEnvironment(
    'PROTO_LIVE_CATALOG',
    defaultValue: false,
  );

  /// Explicit Day 11 order opt-in; local orders remain the default.
  static const liveOrders = bool.fromEnvironment(
    'PROTO_LIVE_ORDERS',
    defaultValue: false,
  );

  /// Read-only customer delivery details, effective with live orders.
  static const liveDeliveryStatus = bool.fromEnvironment(
    'PROTO_LIVE_DELIVERY_STATUS',
    defaultValue: false,
  );
  static const defaultProductionBaseUrl = String.fromEnvironment(
    'PROTO_PRODUCTION_API_BASE_URL',
    defaultValue: '',
  );

  /// Kept for Day 7 callers. The app does not use it for local requests.
  static const baseUrl = defaultDevelopmentBaseUrl;

  final ApiEnvironment environment;
  final String developmentBaseUrl;
  final String productionBaseUrl;

  String get resolvedBaseUrl {
    final value =
        (environment == ApiEnvironment.development
                ? developmentBaseUrl
                : productionBaseUrl)
            .trim();
    final uri = Uri.tryParse(value);
    if (uri == null ||
        !uri.hasScheme ||
        uri.host.isEmpty ||
        (uri.scheme != 'http' && uri.scheme != 'https')) {
      throw StateError('Configure a valid ${environment.name} API base URL.');
    }
    return value.replaceFirst(RegExp(r'/+$'), '');
  }

  Uri resolve(String path) {
    if (!path.startsWith('/api/v1/')) {
      throw ArgumentError.value(path, 'path', 'Expected an /api/v1/ route.');
    }
    return Uri.parse('${resolvedBaseUrl}$path');
  }
}

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

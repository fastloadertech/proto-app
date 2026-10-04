/// Development placeholder only; no request is made until an API repository is
/// explicitly introduced. Override with --dart-define=PROTO_API_BASE_URL=...
class ApiConfig {
  const ApiConfig._();
  static const baseUrl = String.fromEnvironment(
    'PROTO_API_BASE_URL',
    defaultValue: 'http://localhost:3000',
  );
}

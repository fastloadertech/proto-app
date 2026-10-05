import 'api_config.dart';
import 'api_failure.dart';

/// Transport-agnostic request. No HTTP package or live transport is wired in
/// Day 8; tests and future platform clients may provide an implementation.
enum ApiMethod { get, post }

class ApiRequest {
  const ApiRequest({
    required this.method,
    required this.uri,
    required this.headers,
    this.body,
  });
  final ApiMethod method;
  final Uri uri;
  final Map<String, String> headers;
  final Object? body;
}

class ApiResponse {
  const ApiResponse(this.statusCode, this.body);
  final int statusCode;
  final Object? body;
}

abstract interface class ApiTransport {
  Future<ApiResponse> send(ApiRequest request);
}

class ApiClient {
  const ApiClient({required this.transport, this.config = const ApiConfig()});
  final ApiTransport transport;
  final ApiConfig config;

  Future<Object?> get(String path, {String? accessToken}) =>
      send(ApiMethod.get, path, accessToken: accessToken);

  Future<Object?> post(String path, {Object? body, String? accessToken}) =>
      send(ApiMethod.post, path, body: body, accessToken: accessToken);

  Future<Object?> send(
    ApiMethod method,
    String path, {
    Object? body,
    String? accessToken,
  }) async {
    final uri = config.resolve(path);
    final request = ApiRequest(
      method: method,
      uri: uri,
      body: body,
      headers: {
        'Accept': 'application/json',
        if (body != null) 'Content-Type': 'application/json',
        if (accessToken != null && accessToken.isNotEmpty)
          'Authorization': 'Bearer $accessToken',
      },
    );
    late final ApiResponse response;
    try {
      response = await transport.send(request);
    } on ApiFailure {
      rethrow;
    } catch (_) {
      throw ApiFailure.fromStatus(null);
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiFailure.fromResponse(response.statusCode, response.body);
    }
    return response.body;
  }

  static Map<String, dynamic> object(Object? body) {
    if (body is Map) return Map<String, dynamic>.from(body);
    throw const ApiFailure(
      ApiFailureKind.unknown,
      message: 'The service returned an unexpected response.',
    );
  }

  static List<Map<String, dynamic>> objects(Object? body) {
    if (body is List) {
      try {
        return body
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList(growable: false);
      } catch (_) {
        // Fall through to the stable response error below.
      }
    }
    throw const ApiFailure(
      ApiFailureKind.unknown,
      message: 'The service returned an unexpected response.',
    );
  }
}

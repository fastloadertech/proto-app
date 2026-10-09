import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_client.dart';

/// The sole concrete network transport. Screens and repositories see ApiClient.
class HttpApiTransport implements ApiTransport {
  HttpApiTransport({
    http.Client? client,
    this.timeout = const Duration(seconds: 10),
  }) : _client = client ?? http.Client();

  final http.Client _client;
  final Duration timeout;

  @override
  Future<ApiResponse> send(ApiRequest request) async {
    final wireRequest = http.Request(
      request.method == ApiMethod.get ? 'GET' : 'POST',
      request.uri,
    )..headers.addAll(request.headers);
    if (request.body != null) wireRequest.body = jsonEncode(request.body);
    final response = await _client.send(wireRequest).timeout(timeout);
    final bodyText = await response.stream.bytesToString().timeout(timeout);
    Object? body;
    if (bodyText.isNotEmpty) {
      try {
        body = jsonDecode(bodyText);
      } on FormatException {
        body = bodyText;
      }
    }
    return ApiResponse(response.statusCode, body);
  }

  void close() => _client.close();
}

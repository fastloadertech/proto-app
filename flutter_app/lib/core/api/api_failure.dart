enum ApiFailureKind {
  network,
  authentication, // HTTP 401; retained for Day 7 callers.
  forbidden,
  notFound,
  validation,
  conflict,
  server,
  unknown,
}

class ApiFailure implements Exception {
  const ApiFailure(
    this.kind, {
    this.message = 'Something went wrong.',
    this.statusCode,
    this.details = const [],
  });
  final ApiFailureKind kind;
  final String message;
  final int? statusCode;
  final List<String> details;

  factory ApiFailure.fromStatus(int? statusCode, {String? message}) {
    final kind = switch (statusCode) {
      null => ApiFailureKind.network,
      400 || 422 => ApiFailureKind.validation,
      401 => ApiFailureKind.authentication,
      403 => ApiFailureKind.forbidden,
      404 => ApiFailureKind.notFound,
      409 => ApiFailureKind.conflict,
      >= 500 => ApiFailureKind.server,
      _ => ApiFailureKind.unknown,
    };
    return ApiFailure(
      kind,
      statusCode: statusCode,
      message: message ?? _defaultMessage(kind),
    );
  }

  /// Shared NestJS envelope: {statusCode, error, message: string|string[]}.
  factory ApiFailure.fromResponse(int statusCode, Object? body) {
    if (body is! Map) return ApiFailure.fromStatus(statusCode);
    final raw = body['message'];
    final details = raw is List
        ? raw.whereType<String>().toList(growable: false)
        : const <String>[];
    final message = raw is String && raw.trim().isNotEmpty
        ? raw
        : details.isNotEmpty
        ? details.join(' ')
        : null;
    final base = ApiFailure.fromStatus(statusCode, message: message);
    return ApiFailure(
      base.kind,
      message: base.message,
      statusCode: statusCode,
      details: details,
    );
  }

  static String _defaultMessage(ApiFailureKind kind) => switch (kind) {
    ApiFailureKind.network => 'Check your connection and try again.',
    ApiFailureKind.authentication => 'Please sign in again.',
    ApiFailureKind.forbidden => 'You do not have access to this action.',
    ApiFailureKind.notFound => 'This item could not be found.',
    ApiFailureKind.validation => 'Check the information and try again.',
    ApiFailureKind.conflict => 'This request conflicts with a recent change.',
    ApiFailureKind.server => 'The service is unavailable. Try again shortly.',
    ApiFailureKind.unknown => 'Something went wrong.',
  };
  @override
  String toString() => message;
}

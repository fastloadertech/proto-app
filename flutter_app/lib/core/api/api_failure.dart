enum ApiFailureKind {
  network,
  authentication,
  notFound,
  validation,
  server,
  unknown,
}

class ApiFailure implements Exception {
  const ApiFailure(
    this.kind, {
    this.message = 'Something went wrong.',
    this.statusCode,
  });
  final ApiFailureKind kind;
  final String message;
  final int? statusCode;

  factory ApiFailure.fromStatus(int? statusCode, {String? message}) {
    final kind = switch (statusCode) {
      null => ApiFailureKind.network,
      400 || 422 => ApiFailureKind.validation,
      401 || 403 => ApiFailureKind.authentication,
      404 => ApiFailureKind.notFound,
      >= 500 => ApiFailureKind.server,
      _ => ApiFailureKind.unknown,
    };
    return ApiFailure(
      kind,
      statusCode: statusCode,
      message: message ?? _defaultMessage(kind),
    );
  }

  static String _defaultMessage(ApiFailureKind kind) => switch (kind) {
    ApiFailureKind.network => 'Check your connection and try again.',
    ApiFailureKind.authentication => 'Please sign in again.',
    ApiFailureKind.notFound => 'This item could not be found.',
    ApiFailureKind.validation => 'Check the information and try again.',
    ApiFailureKind.server => 'The service is unavailable. Try again shortly.',
    ApiFailureKind.unknown => 'Something went wrong.',
  };
  @override
  String toString() => message;
}

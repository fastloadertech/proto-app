/// Authentication boundary. The local demo has no credentials or token;
/// an API implementation can provide a real session later.
class CustomerSession {
  const CustomerSession({
    required this.customerId,
    required this.phone,
    this.accessToken,
    this.expiresAt,
  });
  final String customerId, phone;
  final String? accessToken;
  final DateTime? expiresAt;
  bool get isAuthenticated =>
      accessToken != null &&
      (expiresAt == null || expiresAt!.isAfter(DateTime.now()));
  Map<String, String> get authorizationHeaders =>
      isAuthenticated ? {'Authorization': 'Bearer $accessToken'} : const {};
}

abstract class AuthRepository {
  CustomerSession? get currentSession;
  Future<CustomerSession> login(String phone);
  Future<void> logout();
}

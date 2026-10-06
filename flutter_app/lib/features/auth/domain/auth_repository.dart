/// Authentication boundary. The local demo has no credentials or token;
/// an API implementation can provide a real session later.
class CustomerSession {
  const CustomerSession({
    required this.customerId,
    required this.phone,
    this.name,
    this.role,
    this.isActive,
    this.accessToken,
    this.expiresAt,
  });
  final String customerId, phone;
  final String? name, role;
  final bool? isActive;
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
  Future<CustomerSession> login(String phone, {String? code});
  Future<CustomerSession?> restoreSession();
  Future<void> logout();
}

abstract interface class AuthSessionStore {
  CustomerSession? get session;
  void save(CustomerSession session);
  void clear();
}

/// Replaceable, memory-only token store. A page refresh discards the JWT.
class MemoryAuthSessionStore implements AuthSessionStore {
  CustomerSession? _session;
  @override
  CustomerSession? get session => _session;
  @override
  void save(CustomerSession session) => _session = session;
  @override
  void clear() => _session = null;
}

class AuthException implements Exception {
  const AuthException(this.message);
  final String message;
  @override
  String toString() => message;
}

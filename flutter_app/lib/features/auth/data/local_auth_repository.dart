import '../domain/auth_repository.dart';

/// In-memory demo sign-in. It never creates a token or contacts an API.
class LocalAuthRepository implements AuthRepository {
  CustomerSession? _session;
  @override
  CustomerSession? get currentSession => _session;
  @override
  Future<CustomerSession> login(String phone, {String? code}) async {
    if (!RegExp(r'^\d{10}$').hasMatch(phone)) {
      throw ArgumentError.value(
        phone,
        'phone',
        'Enter a ten-digit phone number.',
      );
    }
    return _session = CustomerSession(
      customerId: 'demo-customer',
      phone: phone,
    );
  }

  @override
  Future<CustomerSession?> restoreSession() async => _session;

  @override
  Future<void> logout() async {
    _session = null;
  }
}

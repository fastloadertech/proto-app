import '../../../core/api/api_client.dart';
import '../../../core/api/api_models.dart';
import '../../../core/api/api_routes.dart';
import '../domain/auth_repository.dart';

/// Opt-in adapter for a future shared-backend auth contract. No transport is
/// registered by Proto today, and the backend has no login endpoint yet.
class ApiAuthRepository implements AuthRepository {
  ApiAuthRepository(this.client);
  final ApiClient client;
  CustomerSession? _session;

  @override
  CustomerSession? get currentSession => _session;

  @override
  Future<CustomerSession> login(String phone) async {
    final body = await client.post(ApiRoutes.authLogin, body: {'phone': phone});
    return _session = _decodeSession(body);
  }

  Future<CustomerSession> refreshSession() async {
    final body = await client.get(
      ApiRoutes.authMe,
      accessToken: _session?.accessToken,
    );
    return _session = _decodeSession(body);
  }

  @override
  Future<void> logout() async {
    try {
      await client.post(
        ApiRoutes.authLogout,
        accessToken: _session?.accessToken,
      );
    } finally {
      _session = null;
    }
  }

  CustomerSession _decodeSession(Object? body) {
    final dto = AuthSessionDto.fromJson(ApiClient.object(body));
    return CustomerSession(
      customerId: dto.customer.id,
      phone: dto.customer.phone,
      accessToken: dto.accessToken,
      expiresAt: dto.expiresAt,
    );
  }
}

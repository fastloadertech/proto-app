import 'dart:convert';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_failure.dart';
import '../../../core/api/api_models.dart';
import '../../../core/api/api_routes.dart';
import '../domain/auth_repository.dart';

/// Day 9 customer authentication against the shared NestJS backend.
class ApiAuthRepository implements AuthRepository {
  ApiAuthRepository(this.client, {AuthSessionStore? sessionStore})
    : _store = sessionStore ?? MemoryAuthSessionStore();

  final ApiClient client;
  final AuthSessionStore _store;

  @override
  CustomerSession? get currentSession => _store.session;

  @override
  Future<CustomerSession> login(String phone, {String? code}) async {
    if (code == null || !RegExp(r'^\d{6}$').hasMatch(code)) {
      throw const AuthException('Enter the six-digit development code.');
    }
    if (!RegExp(r'^\+[1-9]\d{7,14}$').hasMatch(phone.trim())) {
      throw const AuthException('Enter a valid international phone number.');
    }
    try {
      final body = ApiClient.object(
        await client.post(
          ApiRoutes.authLogin,
          body: {'phone': phone.trim(), 'code': code},
        ),
      );
      final dto = CustomerLoginDto.fromJson(body);
      if (dto.role != 'CUSTOMER' ||
          dto.user.role != 'CUSTOMER' ||
          dto.user.isActive != true ||
          dto.accessToken.isEmpty) {
        throw const AuthException('This customer account cannot sign in.');
      }
      final session = _sessionFor(dto.user, dto.accessToken);
      _store.save(session);
      return session;
    } on ApiFailure catch (error) {
      throw _friendlyFailure(error);
    } on AuthException {
      rethrow;
    } catch (_) {
      throw const AuthException('The sign-in response was not understood.');
    }
  }

  @override
  Future<CustomerSession?> restoreSession() async {
    final existing = _store.session;
    if (existing == null) return null;
    if (!existing.isAuthenticated) {
      _store.clear();
      return null;
    }
    try {
      final profile = CustomerDto.fromJson(
        ApiClient.object(
          await client.get(ApiRoutes.authMe, accessToken: existing.accessToken),
        ),
      );
      if (profile.role != 'CUSTOMER' ||
          profile.isActive != true ||
          profile.id != existing.customerId) {
        _store.clear();
        throw const AuthException('This customer account is disabled.');
      }
      final refreshed = _sessionFor(profile, existing.accessToken!);
      _store.save(refreshed);
      return refreshed;
    } on ApiFailure catch (error) {
      if (error.kind == ApiFailureKind.authentication ||
          error.kind == ApiFailureKind.forbidden ||
          error.kind == ApiFailureKind.notFound) {
        _store.clear();
      }
      throw _friendlyFailure(error);
    } on AuthException {
      rethrow;
    } catch (_) {
      throw const AuthException('The account response was not understood.');
    }
  }

  /// GET /auth/me using the stored Bearer token.
  Future<CustomerSession?> refreshSession() => restoreSession();

  @override
  Future<void> logout() async => _store.clear();

  CustomerSession _sessionFor(CustomerDto customer, String token) =>
      CustomerSession(
        customerId: customer.id,
        name: customer.name,
        phone: customer.phone,
        role: customer.role,
        isActive: customer.isActive,
        accessToken: token,
        expiresAt: _jwtExpiry(token),
      );

  DateTime? _jwtExpiry(String token) {
    try {
      final segments = token.split('.');
      if (segments.length != 3) return null;
      final payload = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(segments[1]))),
      );
      final expiry = payload is Map ? payload['exp'] : null;
      return expiry is int
          ? DateTime.fromMillisecondsSinceEpoch(expiry * 1000, isUtc: true)
          : null;
    } catch (_) {
      return null;
    }
  }

  AuthException _friendlyFailure(ApiFailure error) => switch (error.kind) {
    ApiFailureKind.authentication => const AuthException(
      'Invalid phone number or development code.',
    ),
    ApiFailureKind.forbidden => const AuthException(
      'This customer account is disabled.',
    ),
    ApiFailureKind.notFound => const AuthException(
      'Customer account not found. Check the phone number.',
    ),
    ApiFailureKind.validation => const AuthException(
      'Check the phone number and six-digit code.',
    ),
    ApiFailureKind.conflict => const AuthException(
      'This account changed. Try signing in again.',
    ),
    ApiFailureKind.network => const AuthException(
      'Cannot reach Proto right now. Check the connection and retry.',
    ),
    ApiFailureKind.server => const AuthException(
      'Proto is temporarily unavailable. Try again shortly.',
    ),
    ApiFailureKind.unknown => const AuthException(
      'Sign-in failed. Please try again.',
    ),
  };
}

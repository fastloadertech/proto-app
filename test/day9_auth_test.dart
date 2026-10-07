import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:proto/app/proto_app.dart';
import 'package:proto/core/api/api_client.dart';
import 'package:proto/core/api/api_routes.dart';
import 'package:proto/core/state/app_controller.dart';
import 'package:proto/features/auth/data/api_auth_repository.dart';
import 'package:proto/features/auth/data/local_auth_repository.dart';
import 'package:proto/features/auth/domain/auth_repository.dart';

const _user = {
  'id': 'customer-1',
  'name': 'Proto Customer',
  'phone': '+15550001001',
  'role': 'CUSTOMER',
  'isActive': true,
};
const _login = {'accessToken': 'test-token', 'role': 'CUSTOMER', 'user': _user};

void main() {
  test('API login stores customer identity and Bearer token', () async {
    final transport = _Transport(
      (request) async => const ApiResponse(200, _login),
    );
    final store = MemoryAuthSessionStore();
    AuthRepository auth = ApiAuthRepository(
      ApiClient(transport: transport),
      sessionStore: store,
    );
    final app = AppController(authRepository: auth);
    addTearDown(app.dispose);

    await app.signIn('+15550001001', code: '123456');
    expect(app.currentSession?.customerId, 'customer-1');
    expect(app.currentSession?.name, 'Proto Customer');
    expect(app.currentSession?.phone, '+15550001001');
    expect(app.currentSession?.role, 'CUSTOMER');
    expect(app.currentSession?.isActive, true);
    expect(store.session?.accessToken, 'test-token');
    expect(transport.requests.single.uri.path, ApiRoutes.authLogin);
    expect(transport.requests.single.body, {
      'phone': '+15550001001',
      'code': '123456',
    });
  });

  test(
    'auth/me validates stored token and refreshes customer profile',
    () async {
      final store = MemoryAuthSessionStore()
        ..save(
          const CustomerSession(
            customerId: 'customer-1',
            phone: '+15550001001',
            accessToken: 'test-token',
          ),
        );
      final transport = _Transport(
        (request) async => const ApiResponse(200, _user),
      );
      final auth = ApiAuthRepository(
        ApiClient(transport: transport),
        sessionStore: store,
      );
      final restored = await auth.restoreSession();
      expect(restored?.name, 'Proto Customer');
      expect(transport.requests.single.uri.path, ApiRoutes.authMe);
      expect(
        transport.requests.single.headers['Authorization'],
        'Bearer test-token',
      );
      await auth.logout();
      expect(store.session, isNull);
      expect(
        transport.requests,
        hasLength(1),
      ); // No unsupported logout endpoint.
    },
  );

  for (final (status, expected) in [
    (400, 'Check the phone number'),
    (401, 'Invalid phone number'),
    (403, 'disabled'),
    (404, 'not found'),
    (409, 'changed'),
    (500, 'temporarily unavailable'),
  ]) {
    test('login maps HTTP $status to a safe message', () async {
      final transport = _Transport(
        (request) async => ApiResponse(status, {
          'statusCode': status,
          'message': 'Internal server detail must not appear',
        }),
      );
      final auth = ApiAuthRepository(ApiClient(transport: transport));
      await expectLater(
        auth.login('+15550001001', code: '123456'),
        throwsA(
          isA<AuthException>().having(
            (error) => error.message,
            'message',
            contains(expected),
          ),
        ),
      );
      expect(auth.currentSession, isNull);
    });
  }

  test(
    'network failure and timeout stay retryable without a session',
    () async {
      for (final error in [
        StateError('offline'),
        TimeoutException('timed out'),
      ]) {
        final transport = _Transport((request) async => throw error);
        final auth = ApiAuthRepository(ApiClient(transport: transport));
        await expectLater(
          auth.login('+15550001001', code: '123456'),
          throwsA(
            isA<AuthException>().having(
              (failure) => failure.message,
              'message',
              contains('connection'),
            ),
          ),
        );
        expect(auth.currentSession, isNull);
      }
    },
  );

  test('401 from auth/me clears an invalid stored session', () async {
    final store = MemoryAuthSessionStore()
      ..save(
        const CustomerSession(
          customerId: 'customer-1',
          phone: '+15550001001',
          accessToken: 'expired-token',
        ),
      );
    final auth = ApiAuthRepository(
      ApiClient(
        transport: _Transport(
          (request) async =>
              const ApiResponse(401, {'message': 'Unauthorized'}),
        ),
      ),
      sessionStore: store,
    );
    await expectLater(auth.restoreSession(), throwsA(isA<AuthException>()));
    expect(store.session, isNull);
  });

  test('local repository remains a token-free fallback', () async {
    final app = AppController(authRepository: LocalAuthRepository());
    addTearDown(app.dispose);
    await app.signInDemo('9876543210');
    expect(app.currentSession?.accessToken, isNull);
    expect((await app.restoreSession())?.phone, '9876543210');
    await app.signOut();
    expect(app.currentSession, isNull);
  });

  testWidgets('live auth handles invalid code and login, profile, logout', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var invalid = true;
    final transport = _Transport((request) async {
      if (invalid) {
        return const ApiResponse(401, {'message': 'Invalid development code.'});
      }
      return const ApiResponse(200, _login);
    });
    await tester.pumpWidget(
      ProtoApp(
        liveAuth: true,
        authRepository: ApiAuthRepository(ApiClient(transport: transport)),
      ),
    );
    await tester.pump(const Duration(milliseconds: 1400));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), '+15550001001');
    await tester.ensureVisible(find.text('Continue'));
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, '123456');
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();
    expect(
      find.text('Invalid phone number or development code.'),
      findsOneWidget,
    );
    invalid = false;
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();
    expect(find.text('Fuel your next level.'), findsOneWidget);
    await tester.tap(find.text('You').last);
    await tester.pumpAndSettle();
    expect(find.text('Proto Customer'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Log out'),
      180,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(find.text('Log out'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Log out'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Log out').last);
    await tester.pumpAndSettle();
    expect(find.text('Customer sign-in'), findsNothing);
    expect(find.text('Explore as guest'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _Transport implements ApiTransport {
  _Transport(this.handler);
  final Future<ApiResponse> Function(ApiRequest) handler;
  final List<ApiRequest> requests = [];
  @override
  Future<ApiResponse> send(ApiRequest request) {
    requests.add(request);
    return handler(request);
  }
}

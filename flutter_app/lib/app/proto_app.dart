import 'package:flutter/material.dart';

import '../core/api/api_client.dart';
import '../core/api/api_config.dart';
import '../core/api/http_api_transport.dart';
import '../core/state/app_controller.dart';
import '../core/theme/proto_theme.dart';
import '../features/auth/data/api_auth_repository.dart';
import '../features/auth/domain/auth_repository.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/splash_screen.dart';
import '../features/bag/presentation/bag_screen.dart';
import '../features/checkout/presentation/checkout_screen.dart';
import '../features/checkout/presentation/delivery_address_screen.dart';
import '../features/orders/presentation/orders_screen.dart';
import 'main_shell.dart';

class ProtoApp extends StatefulWidget {
  const ProtoApp({
    super.key,
    this.liveAuth = ApiConfig.liveCustomerAuth,
    this.authRepository,
  });
  final bool liveAuth;
  final AuthRepository? authRepository;
  @override
  State<ProtoApp> createState() => _ProtoAppState();
}

class _ProtoAppState extends State<ProtoApp> {
  late final HttpApiTransport? _transport =
      widget.liveAuth && widget.authRepository == null
      ? HttpApiTransport()
      : null;
  late final _controller = AppController(
    authRepository:
        widget.authRepository ??
        (_transport == null
            ? null
            : ApiAuthRepository(ApiClient(transport: _transport))),
  );
  @override
  void dispose() {
    _controller.dispose();
    _transport?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AppScope(
    controller: _controller,
    child: MaterialApp(
      title: 'Proto — Fuel your next level',
      debugShowCheckedModeBanner: false,
      theme: ProtoTheme.theme,
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => SplashScreen(
          onComplete: () async {
            CustomerSession? session;
            try {
              session = await _controller.restoreSession();
            } catch (_) {
              // A failed restore returns to sign-in; the repository owns token state.
            }
            if (!context.mounted) return;
            Navigator.of(
              context,
            ).pushReplacementNamed(session == null ? '/login' : '/shop');
          },
        ),
        '/login': (context) => LoginScreen(
          liveAuth: widget.liveAuth,
          onDemoSignIn: AppScope.of(context).signInDemo,
          onApiSignIn: (phone, code) =>
              AppScope.of(context).signIn(phone, code: code),
          onContinue: () => Navigator.of(
            context,
          ).pushNamedAndRemoveUntil('/shop', (_) => false),
        ),
        '/shop': (context) => MainShell(liveAuth: widget.liveAuth),
        '/bag': (context) => BagScreen(
          standalone: true,
          onBrowse: () => Navigator.of(context).popUntil(
            (route) => route.settings.name == '/shop' || route.isFirst,
          ),
        ),
        '/checkout': (context) => const CheckoutScreen(),
        '/addresses': (context) => const DeliveryAddressScreen(),
        '/orders': (context) => const OrdersScreen(),
      },
    ),
  );
}

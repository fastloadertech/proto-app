import 'dart:async';

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
import '../features/catalog/data/api_catalog_repository.dart';
import '../features/catalog/domain/catalog_repository.dart';
import '../features/checkout/presentation/checkout_screen.dart';
import '../features/checkout/presentation/delivery_address_screen.dart';
import '../features/orders/presentation/orders_screen.dart';
import 'main_shell.dart';

class ProtoApp extends StatefulWidget {
  const ProtoApp({
    super.key,
    this.liveAuth = ApiConfig.liveCustomerAuth,
    this.liveCatalog = ApiConfig.liveCatalog,
    this.authRepository,
    this.catalogRepository,
  });
  final bool liveAuth;
  final bool liveCatalog;
  final AuthRepository? authRepository;
  final CatalogRepository? catalogRepository;
  @override
  State<ProtoApp> createState() => _ProtoAppState();
}

class _ProtoAppState extends State<ProtoApp> {
  late final HttpApiTransport? _transport =
      (widget.liveAuth && widget.authRepository == null) ||
          (widget.liveCatalog && widget.catalogRepository == null)
      ? HttpApiTransport()
      : null;
  late final ApiClient? _client = _transport == null
      ? null
      : ApiClient(transport: _transport);
  late final _controller = AppController(
    authRepository:
        widget.authRepository ??
        (widget.liveAuth ? ApiAuthRepository(_client!) : null),
    catalogRepository:
        widget.catalogRepository ??
        (widget.liveCatalog ? ApiCatalogRepository(_client!) : null),
  );
  @override
  void initState() {
    super.initState();
    if (widget.liveCatalog) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_controller.refreshCatalog());
      });
    }
  }

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

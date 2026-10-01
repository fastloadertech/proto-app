import 'package:flutter/material.dart';

import '../core/state/app_controller.dart';
import '../core/theme/proto_theme.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/splash_screen.dart';
import '../features/bag/presentation/bag_screen.dart';
import '../features/checkout/presentation/checkout_screen.dart';
import '../features/checkout/presentation/delivery_address_screen.dart';
import '../features/orders/presentation/orders_screen.dart';
import 'main_shell.dart';

class ProtoApp extends StatefulWidget {
  const ProtoApp({super.key});
  @override
  State<ProtoApp> createState() => _ProtoAppState();
}

class _ProtoAppState extends State<ProtoApp> {
  final _controller = AppController();
  @override
  void dispose() {
    _controller.dispose();
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
          onComplete: () =>
              Navigator.of(context).pushReplacementNamed('/login'),
        ),
        '/login': (context) => LoginScreen(
          onContinue: () => Navigator.of(
            context,
          ).pushNamedAndRemoveUntil('/shop', (_) => false),
        ),
        '/shop': (context) => const MainShell(),
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

import 'package:flutter/material.dart';

import '../core/state/app_controller.dart';
import '../core/theme/proto_theme.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/splash_screen.dart';
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
      },
    ),
  );
}

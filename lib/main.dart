import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app/proto_app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF10110F),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const ProtoApp());
}

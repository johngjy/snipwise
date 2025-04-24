import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app/app.dart';
import 'app/di/provider_setup.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // 运行应用
  runApp(
    MultiProvider(
      providers: [...globalProviders, ...featureProviders],
      child: const SnipwiseApp(),
    ),
  );
}

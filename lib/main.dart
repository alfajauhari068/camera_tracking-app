import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'routes.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Camera GPS Tracking',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      // ========================================================================
      // ROUTING CONFIGURATION
      // ========================================================================
      
      // Option 1: Menggunakan named routes biasa
      routes: getAppRoutes(),
      initialRoute: AppRoutes.home,

      // Option 2: Menggunakan onGenerateRoute untuk lebih advanced
      // (uncomment jika ingin menggunakan route arguments parsing)
      // onGenerateRoute: onGenerateRoute,
    );
  }
}

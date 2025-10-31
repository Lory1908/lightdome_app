import 'package:flutter/material.dart';

import 'pages/home_scaffold.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.deepPurple,
        brightness: Brightness.dark,
      ),
      useMaterial3: true,
    );

    return MaterialApp(
      title: 'LightDome',
      debugShowCheckedModeBanner: false,
      theme: theme,
      home: const HomeScaffold(),
    );
  }
}

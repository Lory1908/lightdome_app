import 'package:flutter/material.dart';

import 'pages/home_scaffold.dart';
import 'core/persistence/prefs.dart';
import 'controllers/device_controller.dart';
import 'core/services/app_settings.dart';
import 'core/services/device_directory.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Prefs.init();
  await AppSettings.I.restore();
  await DeviceDirectory.I.restore();
  await DeviceController.I.restoreLastDevice();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: Colors.teal,
      brightness: Brightness.dark,
    );
    final theme = ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        scrolledUnderElevation: 0,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        isDense: true,
        border: OutlineInputBorder(),
      ),
      cardTheme: CardThemeData(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 64,
        indicatorShape: const StadiumBorder(),
        backgroundColor: colorScheme.surface,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      sliderTheme: const SliderThemeData(showValueIndicator: ShowValueIndicator.never),
      visualDensity: VisualDensity.standard,
    );

    return MaterialApp(
      title: 'LightDome',
      debugShowCheckedModeBanner: false,
      theme: theme,
      home: const HomeScaffold(),
    );
  }
}

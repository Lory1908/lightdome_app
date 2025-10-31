import 'package:flutter/material.dart';

import '../controllers/device_controller.dart';
import 'tabs/dashboard_page.dart';
import 'tabs/live_page.dart';
import 'tabs/programs_page.dart';
import 'tabs/settings_page.dart';

class HomeScaffold extends StatefulWidget {
  const HomeScaffold({super.key});

  @override
  State<HomeScaffold> createState() => _HomeScaffoldState();
}

class _HomeScaffoldState extends State<HomeScaffold> {
  int _idx = 0;

  final _pages = const [
    DashboardPage(),
    LivePage(),
    ProgramsPage(),
    SettingsPage(),
  ];

  @override
  void initState() {
    super.initState();
    // No auto-discovery yet; user sets IP in Settings.
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = DeviceController.I;
    return AnimatedBuilder(
      animation: ctrl,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: Text('LightDome ${ctrl.ip.isNotEmpty ? '• ${ctrl.ip}' : ''}'),
          ),
          body: _pages[_idx],
          bottomNavigationBar: NavigationBar(
            selectedIndex: _idx,
            onDestinationSelected: (i) => setState(() => _idx = i),
            destinations: const [
              NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Dashboard'),
              NavigationDestination(icon: Icon(Icons.tune_outlined), selectedIcon: Icon(Icons.tune), label: 'Live'),
              NavigationDestination(icon: Icon(Icons.playlist_play_outlined), selectedIcon: Icon(Icons.playlist_play), label: 'Programmi'),
              NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: 'Impostazioni'),
            ],
          ),
        );
      },
    );
  }
}


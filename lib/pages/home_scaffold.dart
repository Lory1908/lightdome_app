import 'package:flutter/material.dart';

import '../controllers/device_controller.dart';
import 'tabs/dashboard_page.dart';
import 'tabs/live_page.dart';
import 'tabs/programs_page.dart';
import 'tabs/settings_page.dart';
import 'tabs/preview_page.dart';
import '../core/services/app_settings.dart';

class HomeScaffold extends StatefulWidget {
  const HomeScaffold({super.key});

  @override
  State<HomeScaffold> createState() => _HomeScaffoldState();
}

class _HomeScaffoldState extends State<HomeScaffold> {
  int _idx = 0;
  bool _withPreviewPrev = true;

  List<Widget> _buildPages(bool withPreview) => withPreview
      ? const [DashboardPage(), PreviewPage(), LivePage(), ProgramsPage(), SettingsPage()]
      : const [DashboardPage(), LivePage(), ProgramsPage(), SettingsPage()];

  @override
  void initState() {
    super.initState();
    // No auto-discovery yet; user sets IP in Settings.
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = DeviceController.I;
    final settings = AppSettings.I;
    return AnimatedBuilder(
      animation: Listenable.merge([ctrl, settings]),
      builder: (context, _) {
        final withPreview = settings.showPreview;
        final pages = _buildPages(withPreview);
        // Map index when the preview tab is toggled without changing page unexpectedly
        var idx = _idx;
        if (withPreview != _withPreviewPrev) {
          if (!withPreview && _withPreviewPrev) {
            // Removed preview: tabs at >=2 shift left by 1
            if (idx >= 2) idx = idx - 1;
          } else if (withPreview && !_withPreviewPrev) {
            // Added preview: tabs at >=2 shift right by 1
            if (idx >= 2) idx = idx + 1;
          }
          _withPreviewPrev = withPreview; // remember
          // clamp to valid range
          if (idx >= pages.length) idx = pages.length - 1;
          if (idx < 0) idx = 0;
          _idx = idx; // keep internal state consistent
        }
        // Extra safety clamp (handles manual changes)
        if (idx >= pages.length) idx = pages.length - 1;
        if (idx < 0) idx = 0;
        return Scaffold(
          appBar: AppBar(
            title: Text('LightDome ${ctrl.ip.isNotEmpty ? '• ${ctrl.ip}' : ''}'),
          ),
          body: pages[idx],
          bottomNavigationBar: NavigationBar(
            selectedIndex: idx,
            onDestinationSelected: (i) => setState(() => _idx = i),
            destinations: [
              const NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Dashboard'),
              if (withPreview)
                const NavigationDestination(icon: Icon(Icons.remove_red_eye_outlined), selectedIcon: Icon(Icons.remove_red_eye), label: 'Anteprima'),
              const NavigationDestination(icon: Icon(Icons.tune_outlined), selectedIcon: Icon(Icons.tune), label: 'Live'),
              const NavigationDestination(icon: Icon(Icons.playlist_play_outlined), selectedIcon: Icon(Icons.playlist_play), label: 'Programmi'),
              const NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: 'Impostazioni'),
            ],
          ),
        );
      },
    );
  }
}

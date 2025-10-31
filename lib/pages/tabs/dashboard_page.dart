import 'package:flutter/material.dart';

import '../../controllers/device_controller.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = DeviceController.I;
    return AnimatedBuilder(
      animation: ctrl,
      builder: (context, _) {
        final st = ctrl.state;
        return RefreshIndicator(
          onRefresh: () async => ctrl.refreshOnce(),
          child: ListView(
            padding: const EdgeInsets.all(12),
            children: [
              _kv('Connessione', ctrl.isConnected ? 'OK' : 'Non connesso'),
              _kv('Stato', st.on ? 'Acceso' : 'Spento'),
              _kv('Modalita', st.mode),
              _kv('Intensita y', '${(st.y * 100).toStringAsFixed(0)}%'),
              _kv('Brightness', '${(st.brightness * 100).toStringAsFixed(0)}%'),
              _kv('Gamma', st.gamma.toStringAsFixed(1)),
              if (st.programName != null) _kv('Programma', st.programName!),
              if (st.sr > 0) _kv('Sample rate', '${st.sr} Hz'),
              _kv('Loop', st.loop ? 'Si' : 'No'),
              if (st.fwVersion != null) _kv('FW', st.fwVersion!),
              if (st.uptime != null) _kv('Uptime', '${st.uptime} s'),
              const SizedBox(height: 24),
              Wrap(
                spacing: 8,
                children: [
                  ElevatedButton.icon(
                    onPressed: ctrl.refreshOnce,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Aggiorna'),
                  ),
                  ElevatedButton.icon(
                    onPressed: ctrl.off,
                    icon: const Icon(Icons.power_settings_new),
                    label: const Text('Spegni'),
                  ),
                ],
              )
            ],
          ),
        );
      },
    );
  }

  Widget _kv(String k, String v) {
    return ListTile(
      dense: true,
      title: Text(k),
      trailing: Text(v, style: const TextStyle(fontWeight: FontWeight.w600)),
    );
  }
}


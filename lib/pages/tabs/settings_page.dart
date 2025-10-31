import 'package:flutter/material.dart';

import '../../controllers/device_controller.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _ipCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _ipCtrl.text = DeviceController.I.ip;
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = DeviceController.I;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Connessione', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          controller: _ipCtrl,
          decoration: const InputDecoration(
            labelText: 'Indirizzo IP o mDNS',
            hintText: 'es. 192.168.1.50 oppure http://cupolaled.local',
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            ElevatedButton.icon(
              onPressed: () {
                final ip = _ipCtrl.text.trim();
                ctrl.setIp(ip);
              },
              icon: const Icon(Icons.link),
              label: const Text('Connetti'),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: ctrl.disconnect,
              icon: const Icon(Icons.link_off),
              label: const Text('Disconnetti'),
            ),
          ],
        ),
        const SizedBox(height: 24),
        const Text('Preferenze', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text('Tema scuro attivo. Altre preferenze arriveranno più avanti.'),
        const SizedBox(height: 24),
        const Text('Note', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text(
          'Questa versione usa solo HTTP in LAN, senza cloud.\n'
          'Il polling è attivo a ~5 Hz. Le azioni LIVE sono rate-limited a ~60 Hz.',
        ),
      ],
    );
  }
}


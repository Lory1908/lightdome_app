import 'package:flutter/material.dart';

import '../../controllers/device_controller.dart';

class ProgramsPage extends StatefulWidget {
  const ProgramsPage({super.key});

  @override
  State<ProgramsPage> createState() => _ProgramsPageState();
}

class _ProgramsPageState extends State<ProgramsPage> {
  final _nameCtrl = TextEditingController();
  List<String> _programs = const [];
  bool _loading = false;

  Future<void> _refresh() async {
    setState(() => _loading = true);
    _programs = await DeviceController.I.listPrograms();
    setState(() => _loading = false);
  }

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = DeviceController.I;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Programmi (.ldy)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nome programma',
                  hintText: 'es. demo1',
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: () async {
                final name = _nameCtrl.text.trim();
                if (name.isEmpty) return;
                await ctrl.startProgram(name);
              },
              icon: const Icon(Icons.play_arrow),
              label: const Text('Play'),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: ctrl.stopProgram,
              icon: const Icon(Icons.stop),
              label: const Text('Stop'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            ElevatedButton.icon(
              onPressed: _refresh,
              icon: const Icon(Icons.refresh),
              label: const Text('Aggiorna lista'),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: () async {
                final name = _nameCtrl.text.trim();
                if (name.isEmpty) return;
                await ctrl.deleteProgram(name);
                if (mounted) _refresh();
              },
              icon: const Icon(Icons.delete),
              label: const Text('Delete'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_loading) const LinearProgressIndicator(),
        for (final p in _programs)
          ListTile(
            title: Text(p),
            trailing: Wrap(spacing: 6, children: [
              IconButton(
                icon: const Icon(Icons.play_arrow),
                onPressed: () => ctrl.startProgram(p),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () async { await ctrl.deleteProgram(p); _refresh(); },
              ),
            ]),
            onTap: () => _nameCtrl.text = p,
          ),
        const SizedBox(height: 12),
        const Text(
          'Upload .ldy sarà aggiunto più avanti (richiede file picker).',
          style: TextStyle(color: Colors.white70),
        ),
      ],
    );
  }
}


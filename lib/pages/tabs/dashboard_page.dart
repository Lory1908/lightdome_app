import 'package:flutter/material.dart';

import '../../controllers/device_controller.dart';
import '../../core/models/pattern.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = DeviceController.I;
    return AnimatedBuilder(
      animation: ctrl,
      builder: (context, _) {
        final st = ctrl.state;
        final pattern = ctrl.pattern;
        final items = <Widget>[
          _statCard(context, 'Connessione', ctrl.isConnected ? 'Pronta' : 'Non connesso', icon: ctrl.isConnected ? Icons.check_circle : Icons.link_off),
          _statCard(context, 'Stato lampada', st.on ? 'Accesa' : 'Spenta', icon: st.on ? Icons.light_mode : Icons.dark_mode),
          _statCard(context, 'Modalità', _modeLabel(st.mode), icon: Icons.info_outline),
          _statCard(context, 'Livello uscita', '${(st.y * 100).toStringAsFixed(0)}%', icon: Icons.speed),
          _statCard(context, 'Brightness master', '${(st.brightness * 100).toStringAsFixed(0)}%', icon: Icons.brightness_6),
          _statCard(context, 'Gamma', st.gamma.toStringAsFixed(1), icon: Icons.timeline),
          if (pattern.type != PatternType.none)
            _statCard(context, 'Pattern locale', _patternSummary(pattern), icon: Icons.tune),
          if (st.programName != null && st.programName!.isNotEmpty)
            _statCard(context, 'Programma attivo', st.programName!, icon: Icons.playlist_play),
          if (st.sr > 0)
            _statCard(context, 'Campionamento', '${st.sr} Hz', icon: Icons.graphic_eq),
          if (st.loop)
            _statCard(context, 'Loop programmi', 'Attivo', icon: Icons.loop),
          if (st.fwVersion != null) _statCard(context, 'FW', st.fwVersion!, icon: Icons.memory),
          if (st.uptime != null) _statCard(context, 'Uptime', '${st.uptime} s', icon: Icons.timer_outlined),
        ];

        return RefreshIndicator(
          onRefresh: () async => ctrl.refreshOnce(),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final w = constraints.maxWidth;
              final cols = w >= 1100 ? 3 : (w >= 700 ? 2 : 1);
              final cardW = (w - (16 * (cols + 1))) / cols; // padding + gaps
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [for (final it in items) SizedBox(width: cardW, child: it)],
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Wrap(
                        spacing: 8,
                        children: [
                          ElevatedButton.icon(
                            onPressed: ctrl.refreshOnce,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Aggiorna'),
                          ),
                          FilledButton.tonalIcon(
                            onPressed: ctrl.off,
                            icon: const Icon(Icons.power_settings_new),
                            label: const Text('Spegni'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _statCard(BuildContext context, String k, String v, {IconData? icon}) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (icon != null) Icon(icon, color: theme.colorScheme.primary),
            if (icon != null) const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(k, style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                  const SizedBox(height: 4),
                  Text(v, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _modeLabel(String mode) {
    switch (mode) {
      case 'live':
      case 'live_or_idle':
        return 'Controllo in tempo reale';
      case 'program':
        return 'Programma (.ldy)';
      case 'program_ram':
      case 'ram':
        return 'Pattern di prova (RAM)';
      case 'idle':
        return 'In attesa';
      default:
        return mode;
    }
  }

  String _patternSummary(PatternConfig cfg) {
    switch (cfg.type) {
      case PatternType.sine:
        return 'Sine ${cfg.freqHz.toStringAsFixed(1)} Hz';
      case PatternType.pulse:
        final duty = ((cfg.duty ?? 0.5) * 100).round();
        return 'Pulse ${cfg.freqHz.toStringAsFixed(1)} Hz • duty $duty%';
      case PatternType.micReactive:
        return 'Mic reattivo • gain ${cfg.amplitude.toStringAsFixed(1)}x';
      case PatternType.songWaveSpotify:
        return 'Spotify (beta)';
      case PatternType.songWaveOpen:
        return 'Provider aperto';
      case PatternType.none:
        return 'Nessuno';
    }
  }
}

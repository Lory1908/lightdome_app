import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../core/services/signal_monitor.dart';

class PreviewPage extends StatelessWidget {
  const PreviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    final mon = SignalMonitor.I;
    return AnimatedBuilder(
      animation: mon,
      builder: (context, _) {
        final tx = mon.lastTx;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Anteprima Cupola', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Center(
                      child: SizedBox(
                        width: 260,
                        height: 260,
                        child: CustomPaint(painter: _DomePainter(tx, Theme.of(context).colorScheme)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Intensità TX: ${(tx*100).toStringAsFixed(0)}%'),
                    const SizedBox(height: 8),
                    const Text('Suggerimento: se la cupola è offline, l\'anteprima continua a seguire i pattern e il microfono.'),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _DomePainter extends CustomPainter {
  final double y; // 0..1
  final ColorScheme scheme;
  _DomePainter(this.y, this.scheme);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width/2, size.height/2);
    final radius = size.shortestSide/2 - 8;
    // Base dome outline
    final outline = Paint()
      ..color = scheme.outlineVariant
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, radius, outline);

    // Convert y to luminance-only halo
    // Enfatizza differenza tra minimo e massimo: curva non lineare
    final curve = math.pow(y.clamp(0.0, 1.0), 1.8).toDouble();
    final base = scheme.primary;
    final cStrong = base.withValues(alpha: (0.04 + 0.96 * curve).clamp(0.0, 1.0));
    final cSoft = base.withValues(alpha: (0.0 + 0.45 * curve).clamp(0.0, 1.0));
    final fill = Paint()
      ..shader = RadialGradient(
        colors: [cStrong, cSoft, base.withValues(alpha: 0.0)],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius-4, fill);
  }

  @override
  bool shouldRepaint(covariant _DomePainter oldDelegate) => oldDelegate.y != y || oldDelegate.scheme != scheme;
}

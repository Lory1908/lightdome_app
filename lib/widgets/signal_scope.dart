import 'package:flutter/material.dart';
import '../core/services/signal_monitor.dart';

class SignalScope extends StatelessWidget {
  final double height;
  const SignalScope({super.key, this.height = 120});

  @override
  Widget build(BuildContext context) {
    final mon = SignalMonitor.I;
    return AnimatedBuilder(
      animation: mon,
      builder: (context, _) {
        final tx = mon.tx;
        final rx = mon.rx;
        return SizedBox(
          height: height,
          child: CustomPaint(
            painter: _ScopePainter(tx, rx, Theme.of(context).colorScheme),
          ),
        );
      },
    );
  }
}

class _ScopePainter extends CustomPainter {
  final List<double> tx;
  final List<double> rx;
  final ColorScheme scheme;
  _ScopePainter(this.tx, this.rx, this.scheme);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(8));
    canvas.save();
    canvas.clipRRect(rect);
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = scheme.surfaceContainerHighest.withValues(alpha: 0.35),
    );

    final grid = Paint()
      ..color = scheme.outlineVariant.withValues(alpha: 0.35)
      ..strokeWidth = 1;

    // Horizontal divisions (0%, 25%, 50%, 75%)
    for (int i = 1; i < 4; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    // Vertical divisions to help timing perception
    for (int i = 1; i < 6; i++) {
      final x = size.width * i / 6;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    // Zero line (bottom) slightly brighter
    canvas.drawLine(
      Offset(0, size.height - 1),
      Offset(size.width, size.height - 1),
      grid..color = scheme.outlineVariant.withValues(alpha: 0.5),
    );

    void drawSeries(List<double> s, Color c) {
      if (s.length < 2) return;
      final path = Path();
      for (int i = 0; i < s.length; i++) {
        final x = (s.length == 1) ? 0.0 : size.width * i / (s.length - 1);
        final v = s[i].clamp(0.0, 1.0);
        final y = size.height * (1.0 - v);
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      final p = Paint()
        ..color = c.withValues(alpha: 0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      canvas.drawPath(path, p);

      // Draw a subtle fill to highlight intensity
      final fillPath = Path.from(path)
        ..lineTo(size.width, size.height)
        ..lineTo(0, size.height)
        ..close();
      final fillPaint = Paint()
        ..color = c.withValues(alpha: 0.12)
        ..style = PaintingStyle.fill;
      canvas.drawPath(fillPath, fillPaint);
    }

    drawSeries(rx, scheme.tertiary); // device feedback
    drawSeries(tx, scheme.primary); // app output
    if (_isFlat(tx) && _isFlat(rx)) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: 'In attesa del segnale',
          style: TextStyle(color: scheme.onSurfaceVariant.withValues(alpha: 0.7), fontSize: 12),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: size.width - 16);
      final textOffset = Offset((size.width - textPainter.width) / 2, (size.height - textPainter.height) / 2);
      textPainter.paint(canvas, textOffset);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ScopePainter oldDelegate) => true;

  bool _isFlat(List<double> data) {
    if (data.isEmpty) return true;
    const double eps = 1e-3;
    final ref = data.first;
    for (final v in data) {
      if ((v - ref).abs() > eps) return false;
    }
    return true;
  }
}

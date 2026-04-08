import 'package:flutter/material.dart';

class MapLocationPin extends StatelessWidget {
  final double size;
  final Color color;

  const MapLocationPin({
    super.key,
    this.size = 48,
    this.color = const Color(0xFFE53935),
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size * 1.4,
      child: CustomPaint(painter: _PinPainter(color: color)),
    );
  }
}

class _PinPainter extends CustomPainter {
  final Color color;

  const _PinPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final r = w / 2;
    final bodyHeight = h * 0.78;

    final fillPaint = Paint()..color = color;
    final borderPaint = Paint()
      ..color = _darken(color, 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.04;

    final path = Path();
    path.moveTo(w / 2, h);
    path.cubicTo(w * 0.15, bodyHeight * 0.85, 0, bodyHeight * 0.6, 0, r);
    path.arcToPoint(Offset(w, r), radius: Radius.circular(r));
    path.cubicTo(w, bodyHeight * 0.6, w * 0.85, bodyHeight * 0.85, w / 2, h);
    path.close();

    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, borderPaint);

    // white interior circle
    final circleRadius = r * 0.46;
    final circleCenter = Offset(w / 2, r * 0.95);

    canvas.drawCircle(
      circleCenter,
      circleRadius,
      Paint()..color = Colors.white.withValues(alpha: 0.95),
    );

    canvas.drawCircle(
      circleCenter,
      circleRadius * 0.45,
      Paint()..color = color,
    );
  }

  Color _darken(Color color, double amount) {
    final hsl = HSLColor.fromColor(color);
    return hsl
        .withLightness((hsl.lightness - amount).clamp(0.0, 1.0))
        .toColor();
  }

  @override
  bool shouldRepaint(_PinPainter old) => old.color != color;
}

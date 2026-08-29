import 'package:flutter/material.dart';

/// Google "G" logo colors.
class GoogleLogo extends StatelessWidget {
  const GoogleLogo({super.key, this.size = 20});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _GoogleLogoPainter()),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    const blue = Color(0xFF4285F4);
    const red = Color(0xFFEA4335);
    const yellow = Color(0xFFFBBC05);
    const green = Color(0xFF34A853);

    final stroke = radius * 0.38;
    final rect = Rect.fromCircle(center: center, radius: radius - stroke / 2);

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.butt;

    paint.color = blue;
    canvas.drawArc(rect, -0.4, 1.6, false, paint);

    paint.color = green;
    canvas.drawArc(rect, 1.2, 1.2, false, paint);

    paint.color = yellow;
    canvas.drawArc(rect, 2.4, 1.1, false, paint);

    paint.color = red;
    canvas.drawArc(rect, 3.5, 1.2, false, paint);

    final barPaint = Paint()
      ..color = blue
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTWH(center.dx - stroke * 0.1, center.dy - stroke * 0.45, radius, stroke * 0.9),
      barPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

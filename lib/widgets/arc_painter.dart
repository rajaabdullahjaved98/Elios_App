import 'package:flutter/material.dart';
import 'dart:math';

class ArcPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Rect.fromCircle(
      center: size.center(Offset.zero),
      radius: size.width / 2.2,
    );

    // Arc starts at 4π/3 and sweeps 4π/3 radians
    final double arcStartAngle = 4 * pi / 3 - pi / 2; // rotated 90° left
    final double arcSweepAngle = 4 * pi / 3;

    // Use a Linear Gradient to apply top-to-bottom color change
    final Gradient gradient = LinearGradient(
        begin: Alignment.topCenter, // Start at the top
        end: Alignment.bottomCenter, // End at the bottom
        colors: [
          Color(0xFF3E6AC3), // light blue (top)
          Color(0xFF03112E), // dark blue (bottom)
        ],
        stops: [
          0.0,
          0.75
        ]);

    final Paint paint = Paint()
      ..shader = gradient.createShader(rect)
      ..strokeWidth = 35
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, arcStartAngle, arcSweepAngle, false, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

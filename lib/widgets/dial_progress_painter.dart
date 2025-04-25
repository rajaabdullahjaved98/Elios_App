import 'package:flutter/material.dart';
import 'dart:math';

class DialProgressPainter extends CustomPainter {
  final int currentTemp;
  final int minTemp;
  final int maxTemp;

  DialProgressPainter({
    required this.currentTemp,
    required this.minTemp,
    required this.maxTemp,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final tickLength = 10.0;
    final tickPaint = Paint()
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final tickCount = maxTemp - minTemp + 1;
    final angleStep = 2 * pi / tickCount;

    for (int i = 0; i < tickCount; i++) {
      final angle = -pi / 2 + i * angleStep;

      final isActive = (minTemp + i) <= currentTemp;
      tickPaint.color = isActive ? Colors.white : Colors.grey;

      final innerRadius = radius - 20;
      final outerRadius = innerRadius + tickLength;

      final start = Offset(
        center.dx + innerRadius * cos(angle),
        center.dy + innerRadius * sin(angle),
      );

      final end = Offset(
        center.dx + outerRadius * cos(angle),
        center.dy + outerRadius * sin(angle),
      );

      canvas.drawLine(start, end, tickPaint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

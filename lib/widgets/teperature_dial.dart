import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';
import 'arc_painter.dart';
import 'package:google_fonts/google_fonts.dart';

class TemperatureDial extends StatefulWidget {
  final int temperature;
  final ValueChanged<int> onTempChanged;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  final String mode; // 'Temperature' or 'Price'

  const TemperatureDial({
    super.key,
    required this.temperature,
    required this.onTempChanged,
    required this.onIncrement,
    required this.onDecrement,
    required this.mode,
  });

  @override
  State<TemperatureDial> createState() => _TemperatureDialState();
}

class _TemperatureDialState extends State<TemperatureDial> {
  double currentAngle = 0;

  int get minValue => widget.mode == 'Price' ? 20 : 16;
  int get maxValue => widget.mode == 'Price' ? 100 : 30;
  String get label => widget.mode == 'Price' ? 'Rupees' : 'Celsius';

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: _handlePan,
      onPanEnd: _handlePanEnd,
      child: SizedBox(
        height: 340,
        width: 400,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(
              size: const Size(280, 280),
              painter: ArcPainter(),
            ),
            Container(
              height: 200,
              width: 200,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF122E5E), Color(0xFF3E6AC3)],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(
                  color: Colors.black.withOpacity(0.6),
                  width: 2,
                ),
              ),
            ),
            Positioned(
              child: CustomPaint(
                size: const Size(280, 280),
                painter: _ThumbPainter(widget.temperature, minValue, maxValue),
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${widget.temperature}',
                  style: GoogleFonts.orbitron(
                    fontSize: 70,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
                Text(
                  label,
                  style: GoogleFonts.orbitron(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            Positioned(
              left: 70,
              top: 250,
              child: buildControlButton(
                Icons.remove,
                widget.onDecrement,
                widget.temperature == minValue,
              ),
            ),
            Positioned(
              right: 70,
              top: 250,
              child: buildControlButton(
                Icons.add,
                widget.onIncrement,
                widget.temperature == maxValue,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handlePan(DragUpdateDetails details) {
    RenderBox box = context.findRenderObject() as RenderBox;
    Offset local = box.globalToLocal(details.globalPosition);
    const Offset center = Offset(200, 200);

    double dx = local.dx - center.dx;
    double dy = local.dy - center.dy;
    double angleRad = atan2(dy, dx);
    double angleDeg = angleRad * 180 / pi;

    if (angleDeg < 0) angleDeg += 360;

    const double arcStartDeg = 210;
    const double arcEndDeg = 330;
    const double arcSweepDeg = arcEndDeg - arcStartDeg;

    if (angleDeg < arcStartDeg || angleDeg > arcEndDeg) return;

    setState(() {
      currentAngle = angleDeg;
    });

    double t = (currentAngle - arcStartDeg) / arcSweepDeg;
    int newTemp = minValue + (t * (maxValue - minValue)).round();

    widget.onTempChanged(newTemp);
  }

  void _handlePanEnd(DragEndDetails details) {}

  Widget buildControlButton(
      IconData icon, VoidCallback onPressed, bool isDisabled) {
    return Container(
      height: 50,
      width: 50,
      decoration: BoxDecoration(
        gradient: isDisabled
            ? null
            : const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF122E5E), Color(0xFF3E6AC3)],
              ),
        shape: BoxShape.circle,
        boxShadow: isDisabled
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
        border: Border.all(
          color: isDisabled ? Colors.grey : Colors.black.withOpacity(0.6),
          width: 2,
        ),
      ),
      child: IconButton(
        icon: Icon(
          icon,
          size: 32,
          color: isDisabled ? Colors.grey : Colors.white,
        ),
        onPressed: isDisabled ? null : onPressed,
        padding: const EdgeInsets.all(8),
      ),
    );
  }
}

class _ThumbPainter extends CustomPainter {
  final int temperature;
  final int minTemp;
  final int maxTemp;

  _ThumbPainter(this.temperature, this.minTemp, this.maxTemp);

  @override
  void paint(Canvas canvas, Size size) {
    final double t = (temperature - minTemp) / (maxTemp - minTemp);
    const double arcStartDeg = 210;
    const double arcSweepDeg = 120;

    final double angleDeg = arcStartDeg + arcSweepDeg * t;
    final double angleRad = angleDeg * pi / 180;

    final Offset center = size.center(Offset.zero);
    final double radius = size.width / 2.2;

    final Offset thumbCenter = Offset(
      center.dx + radius * cos(angleRad),
      center.dy + radius * sin(angleRad),
    );

    final Paint paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill
      ..strokeWidth = 3;

    canvas.drawCircle(thumbCenter, 8, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

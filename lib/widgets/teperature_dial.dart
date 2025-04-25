import 'package:flutter/material.dart';
import 'arc_painter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math';

class TemperatureDial extends StatefulWidget {
  final int temperature;
  final ValueChanged<int> onTempChanged;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  const TemperatureDial({
    super.key,
    required this.temperature,
    required this.onTempChanged,
    required this.onIncrement,
    required this.onDecrement,
  });

  @override
  State<TemperatureDial> createState() => _TemperatureDialState();
}

class _TemperatureDialState extends State<TemperatureDial> {
  late Offset center;
  late double radius;
  double currentAngle = 0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: _handlePan,
      onPanEnd: _handlePanEnd,
      child: SizedBox(
        height: 300,
        width: 400,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Arc background
            CustomPaint(
              size: const Size(280, 280),
              painter: ArcPainter(),
            ),

            // Inner circle
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

            // Thumb (circle on arc)
            Positioned(
              child: CustomPaint(
                size: const Size(280, 280),
                painter: _ThumbPainter(widget.temperature),
              ),
            ),

            // Temperature Text
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
                  'Celsius',
                  style: GoogleFonts.orbitron(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),

            // Minus button (Disabled if temperature is 16)
            Positioned(
              left: 70,
              top: 250,
              child: buildControlButton(
                Icons.remove,
                widget.onDecrement,
                widget.temperature == 16,
              ),
            ),

            // Plus button (Disabled if temperature is 30)
            Positioned(
              right: 70,
              top: 250,
              child: buildControlButton(
                Icons.add,
                widget.onIncrement,
                widget.temperature == 30,
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
    const Offset center = Offset(200, 200); // Center of dial

    double dx = local.dx - center.dx;
    double dy = local.dy - center.dy;
    double angleRad = atan2(dy, dx);
    double angleDeg = angleRad * 180 / pi;

    // Wrap angle to 0–360
    if (angleDeg < 0) angleDeg += 360;

    const double arcStartDeg = 210;
    const double arcEndDeg = 330;
    const double arcSweepDeg = arcEndDeg - arcStartDeg;

    if (angleDeg < arcStartDeg || angleDeg > arcEndDeg) return;

    // Update current angle and calculate temperature
    setState(() {
      currentAngle = angleDeg;
    });

    double t = (currentAngle - arcStartDeg) / arcSweepDeg;

    const int minTemp = 16;
    const int maxTemp = 30;

    int newTemp = minTemp + (t * (maxTemp - minTemp)).round();

    widget.onTempChanged(newTemp);
  }

  void _handlePanEnd(DragEndDetails details) {
    // Optional: You can perform any clean-up or final adjustments if needed after the drag ends.
  }

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

// Painter for drawing the seekbar thumb (circle on arc)
class _ThumbPainter extends CustomPainter {
  final int temperature;
  static const int minTemp = 16;
  static const int maxTemp = 30;

  _ThumbPainter(this.temperature);

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

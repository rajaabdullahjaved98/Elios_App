import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DataBox extends StatefulWidget {
  final String title;
  final Gradient backgroundGradient;
  final Color textColor;
  final Widget? child;

  const DataBox({
    super.key,
    required this.title,
    this.backgroundGradient = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF092D5F), Color(0xFF092D5F)],
    ),
    this.textColor = Colors.white,
    this.child,
  });

  @override
  State<DataBox> createState() => _DataBox();
}

class _DataBox extends State<DataBox> {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      height: 320,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: widget.backgroundGradient,
        borderRadius: BorderRadius.circular(40),
        border: Border.all(
          color: const Color(0xFF122E5E),
          width: 1.5,
          style: BorderStyle.solid,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            spreadRadius: 4,
            blurRadius: 12,
            offset: const Offset(4, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            widget.title,
            textAlign: TextAlign.center,
            style: GoogleFonts.orbitron(
              color: widget.textColor,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Color(0xFF1A397A), width: 9),
            ),
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF135A9B), Color(0xFF2C3368)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.4),
                    spreadRadius: 2,
                    blurRadius: 10,
                    offset: const Offset(2, 4),
                  ),
                ],
              ),
              child: Center(child: widget.child),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class PowerButton extends StatelessWidget {
  final bool isPowerOn;
  final VoidCallback onToggle;

  const PowerButton({
    super.key,
    required this.isPowerOn,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: isPowerOn
              ? const LinearGradient(
                  colors: [Color(0xFF3E6AC3), Color(0xFF122E5E)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                )
              : const LinearGradient(
                  colors: [Color(0xFFE74C3C), Color(0xFFC0392B)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
        ),
        child: Center(
          child: SvgPicture.asset(
            'assets/icons/power-off-solid.svg',
            width: 30,
            height: 30,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

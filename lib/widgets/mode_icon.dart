import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ModeIcon extends StatelessWidget {
  final bool isSelected;
  final String activeIconPath;
  final String inactiveIconPath;
  final VoidCallback onTap;

  const ModeIcon({
    super.key,
    required this.isSelected,
    required this.activeIconPath,
    required this.inactiveIconPath,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final String iconPath = isSelected ? activeIconPath : inactiveIconPath;

    Widget imageWidget;
    if (iconPath.toLowerCase().endsWith('.svg')) {
      imageWidget = SvgPicture.asset(
        iconPath,
        width: 40,
        height: 40,
      );
    } else {
      imageWidget = Image.asset(
        iconPath,
        width: 40,
        height: 40,
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: imageWidget,
    );
  }
}

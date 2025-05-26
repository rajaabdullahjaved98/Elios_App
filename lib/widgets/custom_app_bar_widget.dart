import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomAppBarWidget extends StatelessWidget
    implements PreferredSizeWidget {
  final VoidCallback onDrawerPressed;
  final VoidCallback onToolbarPressed;
  final String title;
  final String logoPath;

  const CustomAppBarWidget({
    Key? key,
    required this.onDrawerPressed,
    required this.onToolbarPressed,
    required this.title,
    this.logoPath = 'assets/images/sabro_white.png',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF03112E), Color(0xFF0666B2)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(20.0),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x96948D8D),
            blurRadius: 5,
            offset: Offset(0, 2.5),
          ),
        ],
      ),
      padding: const EdgeInsets.only(top: 40, bottom: 12, left: 16, right: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top Row (Drawer, Logo, Toolbar)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: SvgPicture.asset(
                  'assets/icons/bars-solid.svg',
                  width: 24,
                  height: 24,
                  color: Colors.white,
                ),
                onPressed: onDrawerPressed,
              ),
              Column(
                children: [
                  // Image.asset(
                  // logoPath,
                  // height: 62,
                  // width: 160,
                  // fit: BoxFit.fill,
                  //color: Colors.white,
                  // ),
                  Text(
                    'Sabro',
                    style: GoogleFonts.orbitron(
                        fontSize: 35,
                        fontWeight: FontWeight.w700,
                        color: Colors.white),
                  )
                ],
              ),
              IconButton(
                icon: SvgPicture.asset(
                  'assets/icons/ellipsis-vertical-solid.svg',
                  width: 24,
                  height: 24,
                  color: Colors.white,
                ),
                onPressed: onToolbarPressed,
              ),
            ],
          ),
          const SizedBox(height: 4),
          // Title
          Text(title,
              style: GoogleFonts.orbitron(
                fontSize: 19,
                fontWeight: FontWeight.w300,
                color: Colors.white,
              )),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(122);
}

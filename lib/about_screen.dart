import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:elios/widgets/custom_app_bar_widget.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String modelName = '1.5 Ton LCD Model';
  String serialNumber = 'SN-238492834';
  String launchNumber = 'LN-571920';
  String launchDate = '22 May, 2025';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0666B2),
      //   appBar: CustomAppBarWidget(
      // onDrawerPressed: () => _scaffoldKey.currentState?.openDrawer(),
      // onToolbarPressed: () {},
      // title: 'About',
      // logoPath: 'assets/images/sabro_white.png',
      //   ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/sabro_white.png',
                width: 190,
                height: 190,
              ),
              const SizedBox(height: 20),
              Text(
                'Digital Inverter',
                style: GoogleFonts.orbitron(
                  fontSize: 22,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                modelName,
                style: GoogleFonts.orbitron(
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 40),
              _buildInfoRow('Serial Number', serialNumber),
              const SizedBox(height: 12),
              _buildInfoRow('Launch Number', launchNumber),
              const SizedBox(height: 12),
              _buildInfoRow('Date', launchDate),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '$label',
          style: GoogleFonts.orbitron(
            fontSize: 15,
            color: Colors.white,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.orbitron(
            fontSize: 15,
            color: Colors.white70,
          ),
        )
      ],
    );
  }
}

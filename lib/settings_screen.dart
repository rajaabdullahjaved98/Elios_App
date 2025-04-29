import 'package:flutter/material.dart';
import 'package:elios/widgets/custom_app_bar_widget.dart';
import 'package:elios/widgets/custom_drawer.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:elios/pairing_screen.dart';

class SettingsScreen extends StatelessWidget {
  // Global key to access Scaffold state
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF03112E),
      key: _scaffoldKey, // Assign the key to the Scaffold
      appBar: CustomAppBarWidget(
        onDrawerPressed: () {
          // Open the drawer when the button is pressed
          _scaffoldKey.currentState?.openDrawer();
        },
        onToolbarPressed: () {
          // Handle toolbar actions here if necessary
        },
        title: 'Settings',
        logoPath: 'assets/images/elios-logo.png',
      ),
      drawer: const CustomDrawer(),
      body: ListView(
        children: [
          const SectionHeader(title: "Pairing Section"),
          SettingsTile(
            imagePath: 'assets/icons/wifi.png',
            title: "Paired Devices",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => PairingScreen()),
              );
            },
          ),
          const SettingsTile(
              imagePath: 'assets/icons/dollar.png',
              title: "Temperature or Price Mode"),
          const SettingsTile(
              imagePath: 'assets/icons/calendar.png', title: "Date and Time"),
          const SectionHeader(title: "Meter Settings"),
          const SettingsTile(
              imagePath: 'assets/icons/electric-meter.png',
              title: "Meter Type"),
          const SettingsTile(
              imagePath: 'assets/icons/info.png', title: "Meter Readings"),
          const SettingsTile(
              imagePath: 'assets/icons/circular.png',
              title: "Reset Usage History"),
          const SectionHeader(title: "About"),
          const SettingsTile(
              imagePath: 'assets/icons/information-button.png', title: "About")
        ],
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  const SectionHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: GoogleFonts.orbitron(
          fontWeight: FontWeight.bold,
          color: Colors.white,
          fontSize: 20,
        ),
      ),
    );
  }
}

class SettingsTile extends StatelessWidget {
  final String imagePath;
  final String title;
  final VoidCallback? onTap;

  const SettingsTile({
    super.key,
    required this.imagePath,
    required this.title,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Material(
        color: Colors.grey.shade800,
        elevation: 4,
        borderRadius: BorderRadius.circular(16),
        shadowColor: Colors.grey.withOpacity(0.2),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap ?? () {},
          splashColor: Colors.white24,
          highlightColor: Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              leading: Image.asset(
                imagePath,
                width: 28,
                height: 28,
              ),
              title: Text(
                title,
                style: GoogleFonts.orbitron(
                  fontSize: 15,
                  color: Colors.white,
                ),
              ),
              trailing: const Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

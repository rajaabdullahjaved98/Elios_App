import 'package:flutter/material.dart';
import 'package:elios/main_screen.dart';
import 'package:elios/data_screen.dart';
import 'package:elios/hourly_usage_screen.dart';
import 'package:elios/daily_usage_screen.dart';
import 'package:elios/monthly_usage_screen.dart';
import 'package:elios/settings_screen.dart';

class CustomDrawer extends StatelessWidget {
  const CustomDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          Container(
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0666B2), Color(0xFF0666B2)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Image.asset(
                    'assets/images/sabro_white.png',
                    width: 130,
                    height: 70,
                    fit: BoxFit.fill,
                  ),
                )
              ],
            ),
          ),
          ListTile(
            leading: Image.asset(
              'assets/icons/home.png',
              width: 20, // Reducing the size of the icon
              height: 20, // Reducing the size of the icon
            ),
            title: Text('Main Screen'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => MainScreen()),
                (route) =>
                    false, // Clears everything and starts fresh with MainScreen
              );
            },
          ),
          ListTile(
            leading: Image.asset(
              'assets/icons/data-analytics.png',
              width: 20, // Reducing the size of the icon
              height: 20, // Reducing the size of the icon
            ),
            title: Text('Data Screen'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => DataScreen()),
                (route) => route.isFirst, // Keeps MainScreen at bottom
              );
            },
          ),
          ListTile(
            leading: Image.asset(
              'assets/icons/hourglass.png',
              width: 20, // Reducing the size of the icon
              height: 20, // Reducing the size of the icon
            ),
            title: Text('Hourly Usage'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => HourlyUsageScreen()),
                (route) => route.isFirst, // Keeps MainScreen at bottom
              );
            },
          ),
          ListTile(
            leading: Image.asset(
              'assets/icons/24-hours.png',
              width: 20, // Reducing the size of the icon
              height: 20, // Reducing the size of the icon
            ),
            title: Text('Daily Usage'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => DailyUsageScreen()),
                (route) => route.isFirst, // Keeps MainScreen at bottom
              );
            },
          ),
          ListTile(
            leading: Image.asset(
              'assets/icons/annual.png',
              width: 20, // Reducing the size of the icon
              height: 20, // Reducing the size of the icon
            ),
            title: Text('Monthly Usage'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => MonthlyUsageScreen()),
                (route) => route.isFirst, // Keeps MainScreen at bottom
              );
            },
          ),
          ListTile(
            leading: Image.asset(
              'assets/icons/setting.png',
              width: 20, // Reducing the size of the icon
              height: 20, // Reducing the size of the icon
            ),
            title: Text('Settings'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => SettingsScreen()),
                (route) => route.isFirst, // Keeps MainScreen at bottom
              );
            },
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:elios/widgets/custom_app_bar_widget.dart';
import 'package:elios/widgets/custom_drawer.dart';

class MeterTypeScreen extends StatefulWidget {
  const MeterTypeScreen({super.key});

  @override
  State<MeterTypeScreen> createState() => _MeterTypeScreenState();
}

class _MeterTypeScreenState extends State<MeterTypeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String _selectedMeterType = 'Single Phase Meter';

  @override
  void initState() {
    super.initState();
    _loadMeterType();
  }

  Future<void> _loadMeterType() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedMeterType = prefs.getString('meterType') ?? 'Single Phase Meter';
    });
  }

  Future<void> _saveMeterType() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('meterType', _selectedMeterType);

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: Colors.black,
      content: Center(
        child: Text(
          'Meter Type Saved!',
          style: GoogleFonts.orbitron(
            color: Colors.white,
          ),
        ),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF03112E),
      key: _scaffoldKey,
      appBar: CustomAppBarWidget(
        onDrawerPressed: () => _scaffoldKey.currentState?.openDrawer(),
        onToolbarPressed: () {},
        title: 'Meter Type',
        logoPath: 'assets/images/sabro_white.png',
      ),
      drawer: const CustomDrawer(),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Select Meter Type',
                style: GoogleFonts.orbitron(
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey),
                ),
                child: DropdownButton<String>(
                  value: _selectedMeterType,
                  dropdownColor: Colors.black,
                  iconEnabledColor: Colors.white,
                  isExpanded: true,
                  underline: const SizedBox(),
                  style: GoogleFonts.orbitron(
                    fontSize: 15,
                    color: Colors.white,
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'Single Phase Meter',
                      child: Center(child: Text('Single Phase Meter')),
                    ),
                    DropdownMenuItem(
                      value: 'Three Phase Meter',
                      child: Center(child: Text('Three Phase Meter')),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedMeterType = value;
                      });
                    }
                  },
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _saveMeterType,
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
                child: Text(
                  'Save',
                  style: GoogleFonts.orbitron(
                    fontSize: 16,
                    color: const Color(0xFF03112E),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:elios/widgets/custom_app_bar_widget.dart';
import 'package:elios/widgets/custom_drawer.dart';

class MeterReadingsScreen extends StatefulWidget {
  const MeterReadingsScreen({super.key});

  @override
  State<MeterReadingsScreen> createState() => _MeterReadingsScreenState();
}

class _MeterReadingsScreenState extends State<MeterReadingsScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String _meterType = 'Single Phase Meter';

  //Single Phase Fields
  TextEditingController lastMonthUnitsController = TextEditingController();
  TextEditingController lastMonthCostController = TextEditingController();

  //Three Phase Fields
  TextEditingController peakStartController = TextEditingController();
  TextEditingController peakEndController = TextEditingController();
  TextEditingController peakCostController = TextEditingController();
  TextEditingController offPeakCostController = TextEditingController();
  TextEditingController totalUnitsController = TextEditingController();
  TextEditingController totalCostController = TextEditingController();
  TextEditingController peakUnitsController = TextEditingController();
  TextEditingController offPeakUnitsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _meterType = prefs.getString('meterType') ?? 'Single Phase Meter';

      //Load Single Phase
      lastMonthUnitsController.text = prefs.getString('lastMonthUnits') ?? '';
      lastMonthCostController.text = prefs.getString('lastMonthCost') ?? '';

      // Load three phase
      peakStartController.text = prefs.getString('peakStart') ?? '';
      peakEndController.text = prefs.getString('peakEnd') ?? '';
      peakCostController.text = prefs.getString('peakCost') ?? '';
      offPeakCostController.text = prefs.getString('offPeakCost') ?? '';
      totalUnitsController.text = prefs.getString('totalUnits') ?? '';
      totalCostController.text = prefs.getString('totalCost') ?? '';
      peakUnitsController.text = prefs.getString('peakUnits') ?? '';
      offPeakUnitsController.text = prefs.getString('offPeakUnits') ?? '';
    });
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();

    if (_meterType == 'Single Phase Meter') {
      await prefs.setString('lastMonthUnits', lastMonthUnitsController.text);
      await prefs.setString('lastMonthCost', lastMonthCostController.text);
    } else {
      await prefs.setString('peakStart', peakStartController.text);
      await prefs.setString('peakEnd', peakEndController.text);
      await prefs.setString('peakCost', peakCostController.text);
      await prefs.setString('offPeakCost', offPeakCostController.text);
      await prefs.setString('totalUnits', totalUnitsController.text);
      await prefs.setString('totalCost', totalCostController.text);
      await prefs.setString('peakUnits', peakUnitsController.text);
      await prefs.setString('offPeakUnits', offPeakUnitsController.text);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.black,
        content: Center(
          child: Text(
            'Meter Readings Saved!',
            style: GoogleFonts.orbitron(
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {TextInputType keyboardType = TextInputType.number}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: GoogleFonts.orbitron(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.orbitron(color: Colors.white70),
          filled: true,
          fillColor: Colors.black26,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }

  Widget _buildForm() {
    if (_meterType == 'Single Phase Meter') {
      return Column(
        children: [
          _buildTextField('Last Month Units', lastMonthUnitsController),
          _buildTextField('Last Month Cost (Rs)', lastMonthCostController,
              keyboardType: TextInputType.numberWithOptions(decimal: true)),
        ],
      );
    } else {
      return Column(
        children: [
          _buildTextField('Peak Hour Start (0 - 24)', peakStartController),
          _buildTextField('Peak Hour End (0 - 24)', peakEndController),
          _buildTextField('Peak Hour Cost (Rs)', peakCostController,
              keyboardType: TextInputType.numberWithOptions(decimal: true)),
          _buildTextField('Off Peak Hour Cost (Rs)', offPeakCostController,
              keyboardType: TextInputType.numberWithOptions(decimal: true)),
          _buildTextField('Last Month Total Units', totalUnitsController),
          _buildTextField('Last Month Cost (Rs)', totalCostController,
              keyboardType: TextInputType.numberWithOptions(decimal: true)),
          _buildTextField('Last Month Peak Hour Units', peakUnitsController),
          _buildTextField(
              'Last Month Off Peak Hour Units', offPeakUnitsController),
        ],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF03112E),
      appBar: CustomAppBarWidget(
        onDrawerPressed: () => _scaffoldKey.currentState?.openDrawer(),
        onToolbarPressed: () {},
        title: 'Meter Readings',
        logoPath: 'assets/images/sabro_white.png',
      ),
      drawer: const CustomDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildForm(),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _savePreferences,
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
                ),
                child: Text(
                  'Save',
                  style: GoogleFonts.orbitron(
                    color: const Color(0xFF03112E),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

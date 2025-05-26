import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:elios/widgets/custom_app_bar_widget.dart';
import 'package:elios/widgets/custom_drawer.dart';
import 'package:google_fonts/google_fonts.dart';

class ModeScreen extends StatefulWidget {
  const ModeScreen({Key? key}) : super(key: key);

  @override
  State<ModeScreen> createState() => _ModeScreenState();
}

class _ModeScreenState extends State<ModeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String? _selectedMode;
  int _comfortTemp = 24;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedMode = prefs.getString('selectedMode') ?? 'Temperature';
      _comfortTemp = prefs.getInt('comfortTemp') ?? 24;
    });
  }

  Future<void> _savePreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedMode', _selectedMode!);
    if (_selectedMode == 'Price') {
      await prefs.setInt('comfortTemp', _comfortTemp);
    }
  }

  Widget _buildComfortTempDropdown() {
    return Column(
      children: [
        Text(
          'Select Comfort Temperature:',
          style: GoogleFonts.orbitron(
            fontSize: 16,
            color: Colors.white,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: () {
            _showComfortTempSelector();
          },
          child: Container(
            width: 220,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$_comfortTemp  °C',
                  style: GoogleFonts.orbitron(
                    fontSize: 15,
                    color: Colors.white,
                  ),
                ),
                const Icon(Icons.arrow_drop_down, color: Colors.white),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showComfortTempSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SizedBox(
          height: 300,
          child: ListView.builder(
            itemCount: 15, // For temps 16 to 30
            itemBuilder: (context, index) {
              int temp = 16 + index;
              return ListTile(
                title: Center(
                  child: Text(
                    '$temp °C',
                    style: GoogleFonts.orbitron(color: Colors.white),
                  ),
                ),
                onTap: () async {
                  SharedPreferences prefs =
                      await SharedPreferences.getInstance();
                  await prefs.setInt('comfortTemp', temp);
                  setState(() {
                    _comfortTemp = temp;
                  });
                  Navigator.pop(context);
                },
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF03112E),
      key: _scaffoldKey,
      appBar: CustomAppBarWidget(
        onDrawerPressed: () {
          _scaffoldKey.currentState?.openDrawer();
        },
        onToolbarPressed: () {},
        title: 'Mode Selection',
        logoPath: 'assets/images/sabro_white.png',
      ),
      drawer: const CustomDrawer(),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Choose Operation Mode:',
                style: GoogleFonts.orbitron(
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 20),

              // Mode Dropdown
              SizedBox(
                width: 220,
                child: DropdownButton<String>(
                  value: _selectedMode,
                  dropdownColor: Colors.black,
                  iconEnabledColor: Colors.white,
                  isExpanded: true,
                  style: GoogleFonts.orbitron(
                    fontSize: 15,
                    color: Colors.white,
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'Temperature',
                      child: Text('Temperature Mode'),
                    ),
                    DropdownMenuItem(
                      value: 'Price',
                      child: Text('Price Mode'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedMode = value;
                      });
                    }
                  },
                ),
              ),

              const SizedBox(height: 30),

              // Comfort Temp Dropdown (Only if Price mode selected)
              // Comfort Temp Dropdown (Only if Price mode selected)
              if (_selectedMode == 'Price') ...[
                const SizedBox(height: 30),
                _buildComfortTempDropdown(),
                const SizedBox(height: 30),
              ],

              // Save Button
              ElevatedButton(
                onPressed: () async {
                  await _savePreferences();
                  Navigator.pop(context);
                },
                child: Text(
                  'Save',
                  style: GoogleFonts.orbitron(color: Color(0xFF03112E)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

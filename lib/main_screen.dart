import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:elios/widgets/custom_app_bar_widget.dart';
import 'package:elios/widgets/custom_drawer.dart';
import 'package:elios/widgets/teperature_dial.dart';
import 'package:elios/widgets/power_button.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:elios/widgets/mode_icon.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _temp = 16;
  int _selectedMode = -1;
  bool _isPowerOn = false;

  int _fanSpeed = 0; // 0: Off, 1: Low, 2: Medium, 3: High, 4: Auto
  bool _isSwingOn = false;
  bool _isEcoOn = false;
  int _lastSelectedMode = -1;

  late AnimationController _fanRotationController;
  late AnimationController _swingWiggleController;
  late AnimationController _ecoGlowController;
  late Animation<double> _swingAnimation;
  late Animation<double> _ecoAnimation;

  final List<String> fanSpeedLabels = ['Off', 'Low', 'Medium', 'High', 'Auto'];

  @override
  void initState() {
    super.initState();
    _fanRotationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 3000))
      ..repeat();
    _swingWiggleController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500))
      ..repeat(reverse: true);
    _ecoGlowController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000))
      ..repeat(reverse: true);

    _swingAnimation =
        Tween<double>(begin: -0.05, end: 0.05).animate(_swingWiggleController);
    _ecoAnimation =
        Tween<double>(begin: 0.7, end: 1.0).animate(_ecoGlowController);

    _loadSettings();
  }

  @override
  void dispose() {
    _fanRotationController.dispose();
    _swingWiggleController.dispose();
    _ecoGlowController.dispose();
    super.dispose();
  }

  Future<void> sendMqttMessage(String message) async {
    final client = MqttServerClient('192.168.18.104', 'flutter_client');
    client.port = 1883;
    client.keepAlivePeriod = 20;
    client.logging(on: true);

    client.onDisconnected = () => print('❌ MQTT Disconnected');

    final connMessage = MqttConnectMessage()
        .withClientIdentifier('flutter_client')
        .startClean()
        .withWillQos(MqttQos.atLeastOnce);

    client.connectionMessage = connMessage;

    try {
      print('🔌 Connecting to broker...');
      await client.connect();
      print('✅ Connected');
    } catch (e) {
      print('❌ MQTT Connection Failed: $e');
      return;
    }

    final builder = MqttClientPayloadBuilder();
    builder.addString(message);
    print('📤 Sending MQTT message: $message');

    client.publishMessage(
      'ac/control',
      MqttQos.atLeastOnce,
      builder.payload!,
    );

    await Future.delayed(Duration(seconds: 1)); // Wait for delivery
    print('🟢 Message sent. Disconnecting.');
    client.disconnect(); // Clean disconnect
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _temp = prefs.getInt('temp') ?? 16;
      _isPowerOn = prefs.getBool('power') ?? false;
      _selectedMode = prefs.getInt('mode') ?? -1;
      _lastSelectedMode = prefs.getInt('lastMode') ?? -1;
      _fanSpeed = prefs.getInt('fanSpeed') ?? 0;
      _isSwingOn = prefs.getBool('swing') ?? false;
      _isEcoOn = prefs.getBool('eco') ?? false;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('temp', _temp);
    await prefs.setBool('power', _isPowerOn);
    await prefs.setInt('mode', _selectedMode);
    await prefs.setInt('lastMode', _lastSelectedMode);
    await prefs.setInt('fanSpeed', _fanSpeed);
    await prefs.setBool('swing', _isSwingOn);
    await prefs.setBool('eco', _isEcoOn);
  }

  void _togglePower() {
    setState(() {
      _isPowerOn = !_isPowerOn;

      if (!_isPowerOn) {
        // Store the current mode before powering off
        _lastSelectedMode = _selectedMode;
        _selectedMode = -1;
      } else {
        // Restore last mode only if eco mode is off or compatible
        if (_isEcoOn) {
          if (_lastSelectedMode == 0 || _lastSelectedMode == 2) {
            _selectedMode = _lastSelectedMode;
          } else {
            _selectedMode = -1;
          }
        } else {
          _selectedMode = _lastSelectedMode;
        }
      }
    });

    final message = _isPowerOn ? 'POWER ON' : 'POWER OFF';
    sendMqttMessage(message);
    _saveSettings();
  }

  void _cycleFanSpeed() {
    if (!_isPowerOn) return;
    setState(() {
      _fanSpeed = (_fanSpeed + 1) % 5;
    });
    _saveSettings();
  }

  void _toggleSwing() {
    if (!_isPowerOn) return;
    setState(() {
      _isSwingOn = !_isSwingOn;
    });
    _saveSettings();
  }

  void _toggleEco() {
    if (!_isPowerOn) return;

    setState(() {
      _isEcoOn = !_isEcoOn;

      if (_isEcoOn && (_selectedMode != 0 && _selectedMode != 2)) {
        // Store current mode and reset
        _lastSelectedMode = _selectedMode;
        _selectedMode = -1;
      } else if (!_isEcoOn && _selectedMode == -1) {
        // Restore last valid mode if any when eco is turned off
        _selectedMode = _lastSelectedMode;
      }
    });

    _saveSettings();
  }

  void _selectMode(int modeIndex) {
    if (_isPowerOn && (!_isEcoOn || modeIndex == 0 || modeIndex == 2)) {
      setState(() {
        _selectedMode = modeIndex;
      });
      _saveSettings();
    }
  }

  Widget _buildFanSpeedIcon() {
    final rotationSpeed = (_fanSpeed / 4).clamp(0.0, 1.0);
    return GestureDetector(
      onTap: () {
        _cycleFanSpeed();
      },
      child: Column(
        children: [
          RotationTransition(
            turns: _fanRotationController
                .drive(Tween(begin: 0.0, end: rotationSpeed)),
            child: Image.asset('assets/icons/fan-speed.png',
                width: 50, color: Colors.white),
          ),
          const SizedBox(height: 6),
          Text(_isPowerOn ? fanSpeedLabels[_fanSpeed] : 'Off',
              style: GoogleFonts.orbitron(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildSwingIcon() {
    return GestureDetector(
      onTap: _toggleSwing,
      child: Column(
        children: [
          _isPowerOn && _isSwingOn
              ? RotationTransition(
                  turns: _swingAnimation,
                  child: Image.asset('assets/icons/swing.png', width: 35))
              : Image.asset(
                  _isPowerOn && _isSwingOn
                      ? 'assets/icons/swing.png'
                      : 'assets/icons/swing-solid.png',
                  width: 35),
          const SizedBox(height: 6),
          Text(_isPowerOn && _isSwingOn ? 'Swing On' : 'Swing Off',
              style: GoogleFonts.orbitron(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildEcoIcon() {
    return GestureDetector(
      onTap: _toggleEco,
      child: Column(
        children: [
          _isPowerOn && _isEcoOn
              ? FadeTransition(
                  opacity: _ecoAnimation,
                  child: Image.asset('assets/icons/eco-green.png', width: 35))
              : Image.asset(
                  _isPowerOn
                      ? 'assets/icons/eco-solid.png'
                      : 'assets/icons/eco-solid.png',
                  width: 35),
          const SizedBox(height: 6),
          Text(_isPowerOn && _isEcoOn ? 'Eco On' : 'Eco Off',
              style: GoogleFonts.orbitron(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final height = size.height;
    final width = size.width;
    final isSmallScreen = width < 360;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFF03112E),
      appBar: CustomAppBarWidget(
        onDrawerPressed: () {
          _scaffoldKey.currentState?.openDrawer();
        },
        onToolbarPressed: () {},
        title: 'Main Screen',
        logoPath: 'assets/images/elios-logo.png',
      ),
      drawer: const CustomDrawer(),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
              horizontal: width * 0.05, vertical: height * 0.03),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              //AMBIENT AND ROOM TEMP ICONS
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    children: [
                      Image.asset('assets/icons/ambient-temperature.png',
                          height: 30, width: 30), // Replace with your icon
                      SizedBox(height: 4),
                      Text('0.0',
                          style: GoogleFonts.orbitron(
                              color: Colors.white, fontSize: 14)),
                    ],
                  ),
                  Column(
                    children: [
                      Image.asset('assets/icons/room-temperature.png',
                          height: 30, width: 30), // Replace with your icon
                      SizedBox(height: 4),
                      Text('0.0',
                          style: GoogleFonts.orbitron(
                              color: Colors.white, fontSize: 14)),
                    ],
                  ),
                ],
              ),
              SizedBox(height: height * 0.02),

              //TEMPERATUE DIAL
              TemperatureDial(
                temperature: _temp,
                onTempChanged: (value) {
                  setState(() {
                    _temp = value;
                  });
                  _saveSettings();
                },
                onIncrement: () {
                  setState(() {
                    _temp = (_temp + 1).clamp(16, 30);
                  });
                  _saveSettings();
                },
                onDecrement: () {
                  setState(() {
                    _temp = (_temp - 1).clamp(16, 30);
                  });
                  _saveSettings();
                },
              ),
              SizedBox(height: height * 0.02),

              //MODES SECTION
              Text('Modes',
                  style: GoogleFonts.orbitron(
                    fontSize: isSmallScreen ? 14 : 18,
                    color: Colors.white,
                    fontWeight: FontWeight.w200,
                  )),
              SizedBox(height: height * 0.01),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: width * 0.05,
                runSpacing: height * 0.01,
                children: [
                  for (int i = 0; i < 5; i++)
                    ModeIcon(
                      isSelected: _selectedMode == i && _isPowerOn,
                      activeIconPath: 'assets/icons/mode$i-active.png',
                      inactiveIconPath: 'assets/icons/mode$i-inactive.png',
                      onTap: () => _selectMode(i),
                    )
                ],
              ),
              SizedBox(height: height * 0.05),

              // POWER, FAN, SWING, AND ECO SECTION
              Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFF3E6AC3), Color(0xFF122E5E)]),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: Colors.black, width: 1, style: BorderStyle.solid),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 20,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    PowerButton(isPowerOn: _isPowerOn, onToggle: _togglePower),
                    const SizedBox(height: 15),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: width * 0.08,
                      runSpacing: height * 0.015,
                      children: [
                        _buildFanSpeedIcon(),
                        _buildSwingIcon(),
                        _buildEcoIcon(),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

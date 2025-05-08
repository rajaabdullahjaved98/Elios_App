// DEPENDENCIES
import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:typed_data/typed_data.dart';
import 'package:elios/widgets/custom_app_bar_widget.dart';
import 'package:elios/widgets/custom_drawer.dart';
import 'package:elios/widgets/teperature_dial.dart';
import 'package:elios/widgets/power_button.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:elios/widgets/mode_icon.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
// DEPENDENCIES

// MAIN SCREEN STATEFUL WIDGET CLASS
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}
//MAIN SCREEN STATEFUL WIDGET CLASS

// MQTT SERVICE CLASS
class MQTTService {
  final MqttClient client =
      MqttServerClient('192.168.18.104', 'flutter_client');
  final String topic = 'esp32/ac/state';
  final String publishTopic = 'esp32/ac/command';

  // CONSTRUCTOR
  MQTTService() {
    client.logging(on: true);
    client.keepAlivePeriod = 60;
    client.onConnected = _onConnected;
    client.onDisconnected = _onDisconnected;
    client.onSubscribed = _onSubscribed;
  }

  // CONNECT TO MQTT SERVER & SUBSCRIBE TO A TOPIC
  // PARSE THE PAYLOAD IF DATA IS RECEIVED
  Future<void> connect() async {
    try {
      await client.connect();
      //print('Connected to MQTT broker');
      client.subscribe(topic, MqttQos.atLeastOnce);

      client.updates!.listen((List<MqttReceivedMessage<MqttMessage>> messages) {
        final recMessage = messages[0].payload as MqttPublishMessage;
        final Uint8Buffer buffer = recMessage.payload.message;
        final Uint8List payload = Uint8List.fromList(buffer);
        //print('RECEIVED DATA: $payload');
        if (payload.length == 10) {
          _onDataReceived?.call(_parsePayload(payload));
        }
      });
    } catch (e) {
      //print('Error: $e');
      client.disconnect();
    }
  }

  // IF CLIENT IS CONNECTED TO A SERVER
  void _onConnected() {
    //print('MQTT client connected');
  }

  // IF CLIENT IS DISCONNECTED FROM A SERVER
  void _onDisconnected() {
    //print('MQTT client disconnected');
  }

  // IF CLIENT IS SUBSCRIBED TO A TOPIC
  void _onSubscribed(String topic) {
    //print('Subscribed to topic: $topic');
  }

  Function(Map<String, dynamic>)? _onDataReceived;

  // CALLBACK FUNCTION FOR RECEIVING DATA
  void onMessageReceived(Function(Map<String, dynamic>) callback) {
    _onDataReceived = callback;
  }

  // FUNCTION TO PARSE THE INCOMING PAYLOAD
  Map<String, dynamic> _parsePayload(Uint8List payload) {
    int roomTempRaw = (payload[6] << 8) | payload[7];
    double roomTemp = roomTempRaw / 10.0;
    int ambientTempRaw = (payload[8] << 8) | payload[9];
    double ambientTemp = ambientTempRaw / 10.0;
    return {
      'power': payload[0] == 1,
      'temperature': payload[1],
      'mode': payload[2],
      'fan': payload[3],
      'swing': payload[4] == 1,
      'eco': payload[5] == 1,
      'room_temp': roomTemp,
      'ambient_temp': ambientTemp,
    };
  }

  // FUNCTION TO PUBLISH CONTROL DATA TO THE SERVER
  void sendControlPacket({
    required bool power,
    required int temperature,
    required int mode,
    required int fan,
    required bool swing,
    required bool eco,
  }) {
    Uint8List payload = Uint8List(6);
    payload[0] = power ? 1 : 0;
    payload[1] = temperature;
    payload[2] = mode;
    payload[3] = fan;
    payload[4] = swing ? 1 : 0;
    payload[5] = eco ? 1 : 0;

    final builder = MqttClientPayloadBuilder();
    Uint8Buffer buffer = Uint8Buffer()..addAll(payload);
    builder.addBuffer(buffer);

    if (client.connectionStatus?.state == MqttConnectionState.connected) {
      client.publishMessage(
          publishTopic, MqttQos.atLeastOnce, builder.payload!);
    } else {
      //print('MQTT client not connected. Cannot send data');
    }
  }
}

// MAIN SCREEN CLASS IMPLEMENTATION
class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _temp = 16;
  int _selectedMode = -1;
  bool _isPowerOn = false;
  int _fanSpeed = 0;
  bool _isSwingOn = false;
  bool _isEcoOn = false;
  String _roomTemp = '0.0';
  String _ambientTemp = '0.0';
  int _lastSelectedMode = -1;

  // INSTANTIATE MQTT SERVICE CLASS
  final mqttService = MQTTService();

  // ICON ANIMATION CONTROLLERS
  late AnimationController _fanRotationController;
  late AnimationController _swingWiggleController;
  late AnimationController _ecoGlowController;
  late Animation<double> _swingAnimation;
  late Animation<double> _ecoAnimation;

  final List<String> fanSpeedLabels = ['Off', 'Low', 'Medium', 'High', 'Auto'];

  @override
  void initState() {
    super.initState();

    // CONNECT AND RECEIVE AC DATA FROM SERVER
    mqttService.connect();
    mqttService.onMessageReceived(_onACStateReceived);

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

    // LOAD MAIN SCREEN WIDGETS STATE SAVED IN SHARED PREFERENCES
    _loadSettings();
  }

  // MAP LIVE DATA TO LOCAL VARIABLES
  void _onACStateReceived(Map<String, dynamic> acState) {
    //print("AC State Received: $acState");
    setState(() {
      _isPowerOn = acState['power'];
      _temp = acState['temperature'];
      _selectedMode = acState['mode'];
      _fanSpeed = acState['fan'];
      _isSwingOn = acState['swing'];
      _isEcoOn = acState['eco'];
      _roomTemp = acState['room_temp'].toString();
      _ambientTemp = acState['ambient_temp'].toString();
    });
  }

  @override
  void dispose() {
    _fanRotationController.dispose();
    _swingWiggleController.dispose();
    _ecoGlowController.dispose();
    super.dispose();
  }

  // FUNCTION TO LOAD WIDGETS STATE FROM SHARED PREFERENCES
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
      _roomTemp = prefs.getString('room_temp') ?? '0.0';
      _ambientTemp = prefs.getString('ambient_temp') ?? '0.0';
    });
  }

  // FUNCTION TO SAVE WIDGETS STATE TO SHARED PREFERENCES
  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('temp', _temp);
    await prefs.setBool('power', _isPowerOn);
    await prefs.setInt('mode', _selectedMode);
    await prefs.setInt('lastMode', _lastSelectedMode);
    await prefs.setInt('fanSpeed', _fanSpeed);
    await prefs.setBool('swing', _isSwingOn);
    await prefs.setBool('eco', _isEcoOn);
    await prefs.setString('room_temp', _roomTemp);
    await prefs.setString('ambient_temp', _ambientTemp);
  }

  // UI BUILDING METHODS
  // TOGGLE POWER BUTTON
  void _togglePower() {
    setState(() {
      _isPowerOn = !_isPowerOn;

      // PUBLISH DATA TO SERVER
      mqttService.sendControlPacket(
          power: _isPowerOn,
          temperature: _temp,
          mode: _selectedMode,
          fan: _fanSpeed,
          swing: _isSwingOn,
          eco: _isEcoOn);

      if (!_isPowerOn) {
        // STORE THE CURRENT OPERATION MODE BEFORE POWERING OFF
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

    //final message = _isPowerOn ? 'POWER ON' : 'POWER OFF';
    //sendMqttMessage(message);
    // SAVE TO SHARED PREFERNCES
    _saveSettings();
  }

  // FUNCTION TO CYCLE THROUGH DIFFERENT FAN SPEEDS
  void _cycleFanSpeed() {
    if (!_isPowerOn) return;
    setState(() {
      _fanSpeed = (_fanSpeed + 1) % 5;
    });
    _saveSettings();
  }

  // FUNCTION TO TOGGLE SWING
  void _toggleSwing() {
    if (!_isPowerOn) return;
    setState(() {
      _isSwingOn = !_isSwingOn;
    });
    _saveSettings();
    mqttService.sendControlPacket(
        power: _isPowerOn,
        temperature: _temp,
        mode: _selectedMode,
        fan: _fanSpeed,
        swing: _isSwingOn,
        eco: _isEcoOn);
  }

  // FUNCTION TO TOGGLE ECO MODE
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
    mqttService.sendControlPacket(
        power: _isPowerOn,
        temperature: _temp,
        mode: _selectedMode,
        fan: _fanSpeed,
        swing: _isSwingOn,
        eco: _isEcoOn);
  }

  // FUNCTION TO SELECT AND SAVE THE OPERATION MODE
  void _selectMode(int modeIndex) {
    if (_isPowerOn && (!_isEcoOn || modeIndex == 0 || modeIndex == 2)) {
      setState(() {
        _selectedMode = modeIndex;
      });
      _saveSettings();
    }
  }

  // BUILD FAN SPEED ICON
  Widget _buildFanSpeedIcon() {
    final rotationSpeed = (_fanSpeed / 4).clamp(0.0, 1.0);
    return GestureDetector(
      onTap: () {
        _cycleFanSpeed();
        mqttService.sendControlPacket(
            power: _isPowerOn,
            temperature: _temp,
            mode: _selectedMode,
            fan: _fanSpeed,
            swing: _isSwingOn,
            eco: _isEcoOn);
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

  // BUILD SWING ICON
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

  // BUILD ECO MODE ICON
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

  // MAIN UI BUILD FUNCTION
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
                      const SizedBox(height: 4),
                      Text(_ambientTemp,
                          style: GoogleFonts.orbitron(
                              color: Colors.white, fontSize: 14)),
                    ],
                  ),
                  Column(
                    children: [
                      Image.asset('assets/icons/room-temperature.png',
                          height: 30, width: 30), // Replace with your icon
                      const SizedBox(height: 4),
                      Text(_roomTemp,
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
                  mqttService.sendControlPacket(
                      power: _isPowerOn,
                      temperature: _temp,
                      mode: _selectedMode,
                      fan: _fanSpeed,
                      swing: _isSwingOn,
                      eco: _isEcoOn);
                },
                onIncrement: () {
                  setState(() {
                    _temp = (_temp + 1).clamp(16, 30);
                  });
                  _saveSettings();
                  mqttService.sendControlPacket(
                      power: _isPowerOn,
                      temperature: _temp,
                      mode: _selectedMode,
                      fan: _fanSpeed,
                      swing: _isSwingOn,
                      eco: _isEcoOn);
                },
                onDecrement: () {
                  setState(() {
                    _temp = (_temp - 1).clamp(16, 30);
                  });
                  _saveSettings();
                  mqttService.sendControlPacket(
                      power: _isPowerOn,
                      temperature: _temp,
                      mode: _selectedMode,
                      fan: _fanSpeed,
                      swing: _isSwingOn,
                      eco: _isEcoOn);
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
                      onTap: () {
                        _selectMode(i);
                        mqttService.sendControlPacket(
                            power: _isPowerOn,
                            temperature: _temp,
                            mode: _selectedMode,
                            fan: _fanSpeed,
                            swing: _isSwingOn,
                            eco: _isEcoOn);
                      },
                    )
                ],
              ),
              SizedBox(height: height * 0.05),

              // POWER, FAN, SWING, AND ECO SECTION
              Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFF3E6AC3), Color(0xFF122E5E)]),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: Colors.black, width: 1, style: BorderStyle.solid),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black,
                      blurRadius: 20,
                      offset: Offset(0, 5),
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

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wifi_iot/wifi_iot.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:elios/widgets/custom_app_bar_widget.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:location/location.dart';
import 'package:http/http.dart' as http;

class PairingScreen extends StatefulWidget {
  const PairingScreen({Key? key}) : super(key: key);

  @override
  State<PairingScreen> createState() => _PairingScreenState();
}

class _PairingScreenState extends State<PairingScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  List<WifiNetwork> availableEspDevices = [];
  String? selectedDevice;
  final TextEditingController ssidController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController espPasswordController = TextEditingController();

  String status = "Tap 'Scan Devices' to find available ESPs.";

  Future<void> requestPermissions() async {
    await [
      Permission.location,
      Permission.locationWhenInUse,
      Permission.locationAlways,
    ].request();
  }

  Future<void> checkLocationService() async {
    Location location = Location();
    bool serviceEnabled = await location.serviceEnabled();

    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
    }

    if (!serviceEnabled) {
      setState(() {
        status = "Location services are required for WiFi scanning.";
      });
    }
  }

  Future<void> scanNetworks() async {
    setState(() => status = "Scanning for ESP devices...");

    try {
      bool isEnabled = await WiFiForIoTPlugin.isEnabled();
      if (!isEnabled) {
        setState(() => status = "WiFi is disabled. Please enable it first.");
        return;
      }

      List<WifiNetwork>? scannedNetworks =
          await WiFiForIoTPlugin.loadWifiList();
      final filtered = scannedNetworks
              ?.where((network) =>
                  network.ssid != null && network.ssid!.startsWith("ESP_"))
              .toList() ??
          [];

      setState(() {
        availableEspDevices = filtered;
        status = filtered.isNotEmpty
            ? "Select an ESP device to connect."
            : "No ESP devices found.";
      });
    } catch (e) {
      setState(() => status = "Error scanning: $e");
    }
  }

  Future<void> connectToEsp(String ssid) async {
    String espPassword = espPasswordController.text.trim();

    if (espPassword.isEmpty) {
      setState(() => status = "Enter ESP password before connecting.");
      return;
    }

    try {
      setState(() => status = "Connecting to $ssid...");

      bool connected = await WiFiForIoTPlugin.connect(
        ssid,
        password: espPassword,
        joinOnce: true,
        security: NetworkSecurity.WPA,
        withInternet: false,
      );

      if (connected) {
        setState(() {
          selectedDevice = ssid;
          status = "Connected to $ssid. Ready to send credentials.";
        });
      } else {
        setState(() => status = "Failed to connect to $ssid.");
      }
    } catch (e) {
      setState(() => status = "Connection error: $e");
    }
  }

  Future<bool> pingESP() async {
    try {
      final response = await http.get(Uri.parse('http://192.168.4.1:80'));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<void> sendCredentials() async {
    if (selectedDevice == null) {
      setState(() => status = "Please connect to ESP first.");
      return;
    }

    String wifiSsid = ssidController.text.trim();
    String wifiPassword = passwordController.text.trim();

    if (wifiSsid.isEmpty || wifiPassword.isEmpty) {
      setState(() => status = "Enter both SSID and password.");
      return;
    }

    setState(() => status = "Checking ESP connection...");

    final isESPReachable = await pingESP();
    if (!isESPReachable) {
      setState(() => status = "ESP not reachable. Try again.");
      return;
    }

    try {
      setState(() => status = "Connecting to WebSocket...");

      final channel = WebSocketChannel.connect(
        Uri.parse("ws://192.168.4.1:80"),
      );

      channel.sink.add("$wifiSsid;$wifiPassword");
      setState(() => status = "Credentials sent! Wait for ESP to restart.");

      await Future.delayed(Duration(seconds: 5));
      await channel.sink.close();
    } catch (e) {
      setState(() => status = "Failed to send: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    requestPermissions();
    checkLocationService();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFF03112E),
      appBar: CustomAppBarWidget(
        onDrawerPressed: () {
          _scaffoldKey.currentState?.openDrawer();
        },
        onToolbarPressed: () {},
        title: 'Pair Device',
        logoPath: 'assets/images/elios-logo.png',
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ElevatedButton(
              onPressed: scanNetworks,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text("Scan Devices"),
            ),
            const SizedBox(height: 10),
            Text("Available ESP Devices", style: labelStyle()),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: availableEspDevices.length,
                itemBuilder: (context, index) {
                  final ssid = availableEspDevices[index].ssid ?? "";
                  return Card(
                    color: selectedDevice == ssid
                        ? Colors.blueGrey
                        : Colors.grey[850],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      title: Text(ssid,
                          style: const TextStyle(color: Colors.white)),
                      trailing: const Icon(Icons.wifi, color: Colors.white),
                      onTap: () => connectToEsp(ssid),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Text("ESP WiFi Password", style: labelStyle()),
            const SizedBox(height: 6),
            customInput(espPasswordController, "Enter ESP AP password",
                obscure: true),
            const SizedBox(height: 20),
            Text("Home WiFi SSID", style: labelStyle()),
            const SizedBox(height: 6),
            customInput(ssidController, "Enter your WiFi name"),
            const SizedBox(height: 12),
            Text("Home WiFi Password", style: labelStyle()),
            const SizedBox(height: 6),
            customInput(passwordController, "Enter your WiFi password",
                obscure: true),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: sendCredentials,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text("Send WiFi Credentials",
                    style: GoogleFonts.orbitron(fontSize: 16)),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: Text(status,
                  style: GoogleFonts.orbitron(color: Colors.white70)),
            )
          ],
        ),
      ),
    );
  }

  TextStyle labelStyle() {
    return GoogleFonts.orbitron(color: Colors.white70, fontSize: 14);
  }

  Widget customInput(TextEditingController controller, String hint,
      {bool obscure = false}) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.grey[850],
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white30),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.blueAccent),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:elios/widgets/custom_app_bar_widget.dart';
import 'package:elios/services/websocket_service.dart';
import 'package:google_fonts/google_fonts.dart';

class Device {
  final String name;
  final String mac;
  Device({required this.name, required this.mac});
  Map<String, dynamic> toJson() => {'name': name, 'mac': mac};
  factory Device.fromJson(Map<String, dynamic> json) =>
      Device(name: json['name'], mac: json['mac']);
}

class PairingScreen extends StatefulWidget {
  const PairingScreen({super.key});
  @override
  State<PairingScreen> createState() => _PairingScreenState();
}

class _PairingScreenState extends State<PairingScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController ssidController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController deviceNameController = TextEditingController();
  List<Device> pairedDevices = [];

  @override
  void initState() {
    super.initState();
    loadDevices();
  }

  Future<void> saveDevices() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = pairedDevices.map((d) => jsonEncode(d.toJson())).toList();
    prefs.setStringList('pairedDevices', jsonList);
  }

  Future<void> loadDevices() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList('pairedDevices') ?? [];
    setState(() {
      pairedDevices =
          jsonList.map((item) => Device.fromJson(jsonDecode(item))).toList();
    });
  }

  void sendWifiDetailsToESP(WebSocketService ws) {
    final ssid = ssidController.text.trim();
    final password = passwordController.text.trim();
    final deviceName = deviceNameController.text.trim();

    if (ssid.isNotEmpty && password.isNotEmpty && deviceName.isNotEmpty) {
      final message = jsonEncode({
        "type": "wifi-credentials",
        "ssid": ssid,
        "password": password,
        "deviceName": deviceName,
      });
      ws.send(message);
    }
  }

  @override
  void dispose() {
    ssidController.dispose();
    passwordController.dispose();
    deviceNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ws = Provider.of<WebSocketService>(context);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFF03112E),
      appBar: CustomAppBarWidget(
        onDrawerPressed: () => _scaffoldKey.currentState?.openDrawer(),
        onToolbarPressed: () {},
        title: 'Pairing Screen',
        logoPath: 'assets/images/elios-logo.png',
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text("Pair New Device",
                style: GoogleFonts.orbitron(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
            const SizedBox(height: 10),
            Text("Connect to ESP_AP WiFi Before Pairing New Device",
                style: GoogleFonts.orbitron(fontSize: 10, color: Colors.white)),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => ws.connect('ws://192.168.4.1/ws'),
              child: Text("Connect",
                  style: GoogleFonts.orbitron(
                      fontSize: 12, color: Color(0xFF03112E))),
            ),
            const SizedBox(height: 10),
            Text("Status: ${ws.isConnected ? 'Connected' : 'Disconnected'}",
                style: GoogleFonts.orbitron(fontSize: 12, color: Colors.white)),
            const SizedBox(height: 20),
            if (ws.mac != null) ...[
              Text("MAC: ${ws.mac!}",
                  style:
                      GoogleFonts.orbitron(fontSize: 12, color: Colors.white)),
              const SizedBox(height: 20),
              TextField(
                controller: ssidController,
                style: GoogleFonts.orbitron(color: Colors.white, fontSize: 12),
                decoration: buildInputDecoration('Wi-Fi SSID'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: passwordController,
                obscureText: true,
                style: GoogleFonts.orbitron(color: Colors.white, fontSize: 12),
                decoration: buildInputDecoration('Wi-Fi Password'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: deviceNameController,
                style: GoogleFonts.orbitron(color: Colors.white, fontSize: 12),
                decoration: buildInputDecoration('Device Name'),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {
                  sendWifiDetailsToESP(ws);
                  final device =
                      Device(name: deviceNameController.text, mac: ws.mac!);
                  if (!pairedDevices.any((d) => d.mac == device.mac)) {
                    pairedDevices.add(device);
                    saveDevices();
                    setState(() {});
                  }
                },
                child: const Text("Send to ESP"),
              ),
            ],
            const SizedBox(height: 20),
            const Divider(),
            Text("Paired Devices:",
                style: GoogleFonts.orbitron(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: pairedDevices.length,
                itemBuilder: (context, index) {
                  final device = pairedDevices[index];
                  return ListTile(
                    onTap: () => ws.connect('ws://192.168.4.1/ws'),
                    leading: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.circle,
                            color: ws.isConnected ? Colors.green : Colors.red,
                            size: 12),
                        const SizedBox(width: 8),
                        Image.asset('assets/icons/air-conditioner.png',
                            width: 25, height: 25)
                      ],
                    ),
                    title: Text(device.name,
                        style: GoogleFonts.orbitron(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                    subtitle: Text("MAC: ${device.mac}",
                        style: const TextStyle(color: Colors.white)),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.white),
                      onPressed: () {
                        setState(() {
                          pairedDevices.removeAt(index);
                        });
                        saveDevices();
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration buildInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.orbitron(color: Colors.white70, fontSize: 12),
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.white24),
        borderRadius: BorderRadius.circular(10),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.cyanAccent),
        borderRadius: BorderRadius.circular(10),
      ),
      filled: true,
      fillColor: const Color(0xFF102347),
    );
  }
}

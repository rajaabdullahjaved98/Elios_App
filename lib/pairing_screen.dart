import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:elios/widgets/custom_app_bar_widget.dart';
import 'package:google_fonts/google_fonts.dart';

class PairingScreen extends StatefulWidget {
  const PairingScreen({super.key});

  @override
  State<PairingScreen> createState() => _PairingScreenState();
}

class Device {
  final String name;
  final String mac;

  Device({required this.name, required this.mac});

  Map<String, dynamic> toJson() => {'name': name, 'mac': mac};

  factory Device.fromJson(Map<String, dynamic> json) =>
      Device(name: json['name'], mac: json['mac']);
}

class _PairingScreenState extends State<PairingScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  WebSocketChannel? channel;
  bool isConnected = false;
  String statusMessage = 'Disconnected';
  bool macReceived = false;
  String receivedMac = '';

  final TextEditingController ssidController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController deviceNameController = TextEditingController();

  List<Device> pairedDevices = [];

  bool deviceConnectionStatus = false;

  @override
  void initState() {
    super.initState();
    loadDevices();
  }

  void connectToWebSocket() {
    try {
      channel = IOWebSocketChannel.connect('ws://192.168.4.1/ws');

      channel!.stream.listen(
        (message) {
          debugPrint("Received: $message");

          try {
            final decoded = jsonDecode(message);

            if (decoded['type'] == 'device-info' && decoded['mac'] != null) {
              setState(() {
                macReceived = true;
                receivedMac = decoded['mac'];
                statusMessage = "MAC Address Received";
                deviceConnectionStatus = true;
              });
            }

            if (decoded['type'] == 'acknowledgement' &&
                decoded['status'] == 'success') {
              final device = Device(
                name: decoded['deviceName'],
                mac: decoded['mac'],
              );

              if (!pairedDevices.any((d) => d.mac == device.mac)) {
                pairedDevices.add(device);
                saveDevices();
                setState(() {});
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Device "${device.name}" saved!')),
                );
              }
            }
          } catch (e) {
            debugPrint("Invalid JSON received: $e");
          }
        },
        onDone: () {
          setState(() {
            isConnected = false;
            statusMessage = 'Disconnected';
            deviceConnectionStatus = false;
          });
        },
        onError: (error) {
          setState(() {
            isConnected = false;
            statusMessage = 'Connection error';
            deviceConnectionStatus = false;
          });
        },
      );

      setState(() {
        isConnected = true;
        statusMessage = 'Connected';
        deviceConnectionStatus = true;
      });
    } catch (e) {
      setState(() {
        isConnected = false;
        statusMessage = 'Failed to connect';
        deviceConnectionStatus = false;
      });
    }
  }

  void sendWifiDetailsToESP() {
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

      channel?.sink.add(message);
      debugPrint("Sent to ESP: $message");
    } else {
      debugPrint("Please fill in all fields");
    }
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

  @override
  void dispose() {
    channel?.sink.close();
    ssidController.dispose();
    passwordController.dispose();
    deviceNameController.dispose();
    super.dispose();
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
        title: 'Pairing Screen',
        logoPath: 'assets/images/elios-logo.png',
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              "Pair New Device",
              style: GoogleFonts.orbitron(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
            const SizedBox(
              height: 10,
            ),
            Text(
              "Connect to " "ESP_AP WiFi Before Pairing New Device",
              style: GoogleFonts.orbitron(fontSize: 10, color: Colors.white),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: connectToWebSocket,
              child: Text("Connect",
                  style: GoogleFonts.orbitron(
                      fontSize: 12, color: Color(0xFF03112E))),
            ),
            const SizedBox(height: 10),
            Text("Status: $statusMessage",
                style: GoogleFonts.orbitron(fontSize: 12, color: Colors.white)),
            const SizedBox(height: 20),
            if (macReceived) ...[
              Text("MAC: $receivedMac",
                  style:
                      GoogleFonts.orbitron(fontSize: 12, color: Colors.white)),
              const SizedBox(height: 20),
              TextField(
                controller: ssidController,
                style: GoogleFonts.orbitron(color: Colors.white, fontSize: 12),
                decoration: InputDecoration(
                  labelText: 'Wi-Fi SSID',
                  labelStyle:
                      GoogleFonts.orbitron(color: Colors.white70, fontSize: 12),
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
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: passwordController,
                obscureText: true,
                style: GoogleFonts.orbitron(color: Colors.white, fontSize: 12),
                decoration: InputDecoration(
                  labelText: 'Wi-Fi Password',
                  labelStyle:
                      GoogleFonts.orbitron(color: Colors.white70, fontSize: 12),
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
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: deviceNameController,
                style: GoogleFonts.orbitron(color: Colors.white, fontSize: 12),
                decoration: InputDecoration(
                  labelText: 'Device Name',
                  labelStyle:
                      GoogleFonts.orbitron(color: Colors.white70, fontSize: 12),
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
                ),
              ),
              ElevatedButton(
                onPressed: sendWifiDetailsToESP,
                child: const Text("Send to ESP"),
              ),
            ],
            const SizedBox(height: 20),
            const Divider(),
            Text(
              "Paired Devices:",
              style: GoogleFonts.orbitron(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: pairedDevices.length,
                itemBuilder: (context, index) {
                  final device = pairedDevices[index];
                  return ListTile(
                    onTap: connectToWebSocket,
                    leading: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.circle,
                          color: deviceConnectionStatus
                              ? Colors.green
                              : Colors.red,
                          size: 12,
                        ),
                        const SizedBox(
                          width: 8,
                        ),
                        Image.asset(
                          'assets/icons/air-conditioner.png',
                          width: 25,
                          height: 25,
                        )
                      ],
                    ),
                    title: Text(
                      device.name,
                      style: GoogleFonts.orbitron(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                    subtitle: Text("MAC: ${device.mac}",
                        style: TextStyle(color: Colors.white)),
                    trailing: IconButton(
                      icon: const Icon(
                        Icons.delete,
                        color: Colors.white,
                      ),
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
}

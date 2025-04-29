import 'package:flutter/material.dart';
import 'package:wifi_iot/wifi_iot.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class PairingScreen extends StatefulWidget {
  @override
  _PairingScreenState createState() => _PairingScreenState();
}

class _PairingScreenState extends State<PairingScreen> {
  List<WifiNetwork> networks = [];
  bool isLoading = false;
  String? selectedSSID;
  String password = '';
  WebSocketChannel? channel;
  String webSocketStatus = "Disconnected";

  @override
  void initState() {
    super.initState();
    scanForWifi();
  }

  Future<void> scanForWifi() async {
    setState(() {
      isLoading = true;
    });

    await Permission.location.request();
    if (!await Permission.location.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Location permission is required.")));
      return;
    }

    List<WifiNetwork>? wifiList = await WiFiForIoTPlugin.loadWifiList();

    networks = wifiList
        //.where((n) => n.ssid != null && n.ssid!.startsWith("ESP"))
        .where((n) => n.ssid != null)
        .toList();

    setState(() {
      isLoading = false;
    });
  }

  Future<void> connectToWifi(String ssid, String password) async {
    bool connected = await WiFiForIoTPlugin.connect(
      ssid,
      password: password,
      security: NetworkSecurity.WPA,
      joinOnce: true,
    );

    if (connected) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Connected to $ssid")));

      // Wait a moment for IP to settle
      await Future.delayed(Duration(seconds: 20));

      // Try connecting to WebSocket
      connectToWebSocket();
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Failed to Connect")));
    }
  }

  void connectToWebSocket() {
    try {
      channel = WebSocketChannel.connect(Uri.parse('ws://192.168.4.1:81'));
      setState(() {
        webSocketStatus = "Connected to WebSocket";
      });

      // Listen for incoming messages
      channel!.stream.listen(
        (message) {
          print("Received: $message");
        },
        onError: (error) {
          print("WebSocket Error: $error");
          setState(() => webSocketStatus = "WebSocket Error");
        },
        onDone: () {
          print("WebSocket closed.");
          setState(() => webSocketStatus = "WebSocket Closed");
        },
      );
    } catch (e) {
      print("WebSocket connection error: $e");
      setState(() {
        webSocketStatus = "Connection Failed";
      });
    }
  }

  void showPasswordDialog(String ssid) {
    setState(() => selectedSSID = ssid);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Connect to $ssid"),
        content: TextField(
          obscureText: true,
          decoration: InputDecoration(labelText: "Password"),
          onChanged: (value) => password = value,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              connectToWifi(ssid, password);
            },
            child: Text("Connect"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Connect to ESP Wi-Fi")),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: scanForWifi,
              child: ListView.builder(
                itemCount: networks.length,
                itemBuilder: (context, index) {
                  final ssid = networks[index].ssid ?? "Unknown";
                  return ListTile(
                    title: Text(ssid),
                    trailing: ElevatedButton(
                      child: Text("Connect"),
                      onPressed: () => showPasswordDialog(ssid),
                    ),
                  );
                },
              ),
            ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Text(
          webSocketStatus,
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.blueAccent),
        ),
      ),
    );
  }
}

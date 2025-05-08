import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class Device {
  final String name;
  final String mac;

  Device({required this.name, required this.mac});

  Map<String, dynamic> toJson() => {'name': name, 'mac': mac};

  factory Device.fromJson(Map<String, dynamic> json) =>
      Device(name: json['name'], mac: json['mac']);
}

class DeviceConnectionProvider extends ChangeNotifier {
  WebSocketChannel? _channel;
  bool _isConnected = false;
  String _statusMessage = 'Disconnected';
  Device? _currentDevice;

  bool get isConnected => _isConnected;
  String get statusMessage => _statusMessage;
  Device? get currentDevice => _currentDevice;
  WebSocketChannel? get channel => _channel;

  void connect(Device device) {
    _channel = IOWebSocketChannel.connect('ws://192.168.4.1/ws');
    _channel!.stream.listen(
      (message) {
        final decoded = jsonDecode(message);
        debugPrint("Global Channel Received: $message");

        if (decoded['type'] == 'acknowledgement' &&
            decoded['status'] == 'success') {
          _currentDevice = device;
          _isConnected = true;
          _statusMessage = 'Connected';
          notifyListeners();
        }
      },
      onDone: () {
        _isConnected = false;
        _statusMessage = 'Disconnected';
        notifyListeners();
      },
      onError: (error) {
        _isConnected = false;
        _statusMessage = 'Connection error';
        notifyListeners();
      },
    );
  }

  void sendJson(Map<String, dynamic> data) {
    if (_channel != null && _isConnected) {
      _channel!.sink.add(jsonEncode(data));
    }
  }

  void disconnect() {
    _channel?.sink.close();
    _isConnected = false;
    _statusMessage = 'Disconnected';
    _currentDevice = null;
    notifyListeners();
  }
}

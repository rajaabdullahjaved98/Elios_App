import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocketService extends ChangeNotifier {
  WebSocketChannel? _channel;
  bool _isConnected = false;
  String _lastTextMessage = '';
  String? mac;

  bool get isConnected => _isConnected;
  String get lastMessage => _lastTextMessage;

  /// Optional external callback to handle binary data (e.g., 109-byte ESP32 payload)
  void Function(Uint8List data)? onBinaryDataReceived;

  void connect(String url) {
    if (_channel != null) return;

    _channel = IOWebSocketChannel.connect(url);

    _channel!.stream.listen(
      (message) {
        _isConnected = true;
        notifyListeners();

        if (message is String) {
          _lastTextMessage = message;
          _handleTextMessage(message);
        } else if (message is Uint8List) {
          _handleBinaryMessage(message);
        }
      },
      onDone: () {
        _isConnected = false;
        _channel = null;
        notifyListeners();
      },
      onError: (error) {
        debugPrint("WebSocket error: $error");
        _isConnected = false;
        _channel = null;
        notifyListeners();
      },
    );
  }

  void _handleTextMessage(String message) {
    try {
      final decoded = jsonDecode(message);
      if (decoded['type'] == 'device-info' && decoded['mac'] != null) {
        mac = decoded['mac'];
      }
    } catch (e) {
      debugPrint('WebSocket: Invalid JSON: $e');
    }
  }

  void _handleBinaryMessage(Uint8List data) {
    if (onBinaryDataReceived != null) {
      onBinaryDataReceived!(data);
    } else {
      debugPrint(
          "Binary message received (${data.length} bytes), but no handler set.");
    }
  }

  void send(String message) {
    _channel?.sink.add(message);
  }

  void disconnect() {
    _channel?.sink.close();
    _channel = null;
    _isConnected = false;
    notifyListeners();
  }
}

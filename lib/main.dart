import 'package:flutter/material.dart';
import 'main_screen.dart';
import 'package:provider/provider.dart';
import 'pairing_screen.dart';
import 'package:elios/services/websocket_service.dart';

final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

void main() {
  runApp(ChangeNotifierProvider(
    create: (_) => WebSocketService(),
    child: const MyApp(),
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorObservers: [routeObserver],
      title: 'ELIOS',
      debugShowCheckedModeBanner: false,
      home: MainScreen(), // Set the MainScreen as the home screen
    );
  }
}

import 'package:flutter/material.dart';
import 'main_screen.dart'; // Import the HomeScreen

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ELIOS',
      debugShowCheckedModeBanner: false,
      home: MainScreen(), // Set the MainScreen as the home screen
    );
  }
}

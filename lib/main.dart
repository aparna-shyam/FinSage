import 'package:flutter/material.dart';
import 'home_page.dart'; // Import your home page

void main() {
  runApp(FinSageApp());
}

class FinSageApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // Removes the debug banner
      title: 'FinSage',
      home: HomePage(), // Start the app with HomePage
    );
  }
}

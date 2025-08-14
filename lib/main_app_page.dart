// main_app_page.dart
import 'package:flutter/material.dart';

class MainAppPage extends StatelessWidget {
  const MainAppPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Welcome to FinSage!'),
        backgroundColor: const Color(0xFF6B5B95),
      ),
      body: const Center(
        child: Text(
          'You have successfully logged in.',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}

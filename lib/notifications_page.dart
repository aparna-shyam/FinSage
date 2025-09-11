import 'package:flutter/material.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: const Color(0xFF6B5B95),
        elevation: 0,
      ),
      body: const Center(
        child: Text(
          'Notifications will be displayed here.',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}

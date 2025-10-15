import 'package:flutter/material.dart';

// Define the consistent primary color and the gradient colors
const Color _primaryColor = Color(0xFF008080); // Deep Teal
const Color _gradientStart = Color(0xFF2C3E50); // Dark Blue-Purple
const Color _gradientEnd = Color(0xFF4CA1AF); // Lighter Blue-Teal

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          Colors.transparent, // 1. Set Scaffold background to transparent
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: _primaryColor, // Use consistent primary color
        foregroundColor: Colors.white, // Ensures title text is visible
        elevation: 0,
      ),
      // 2. Apply the gradient decoration to the body
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_gradientStart, _gradientEnd],
          ),
        ),
        child: const Center(
          child: Text(
            'Notifications will be displayed here.',
            style: TextStyle(
              fontSize: 18,
              color:
                  Colors.white, // Ensures text is visible on the dark gradient
            ),
          ),
        ),
      ),
    );
  }
}

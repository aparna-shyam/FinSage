// lib/recurring_payments_page.dart

import 'package:flutter/material.dart';

class RecurringPaymentsPage extends StatelessWidget {
  const RecurringPaymentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recurring Payments'),
        backgroundColor: const Color(0xFFD9641E), // Use your orange theme color
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.autorenew, size: 80, color: Color(0xFFD9641E)),
            SizedBox(height: 16),
            Text(
              'Manage your subscriptions and recurring bills here!',
              style: TextStyle(fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }
}

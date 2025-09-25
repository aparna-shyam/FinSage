import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FinancialSetupPage extends StatefulWidget {
  const FinancialSetupPage({super.key});

  @override
  State<FinancialSetupPage> createState() => _FinancialSetupPageState();
}

class _FinancialSetupPageState extends State<FinancialSetupPage> {
  final TextEditingController _incomeController = TextEditingController();
  final TextEditingController _savingsController = TextEditingController();
  final TextEditingController _emergencyController = TextEditingController();

  User? get user => FirebaseAuth.instance.currentUser;

  @override
  void dispose() {
    _incomeController.dispose();
    _savingsController.dispose();
    _emergencyController.dispose();
    super.dispose();
  }

  Future<void> _saveFinancialData() async {
    if (_incomeController.text.isEmpty || _savingsController.text.isEmpty) {
      return;
    }

    final currentUser = user;
    if (currentUser == null) return;

    try {
      await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).set({
        'income': double.tryParse(_incomeController.text) ?? 0,
        'savingsGoal': double.tryParse(_savingsController.text) ?? 0,
        'emergencyFund': double.tryParse(_emergencyController.text) ?? 0,
      }, SetOptions(merge: true));

      Navigator.pop(context); // go back to profile page
    } catch (e) {
      debugPrint('Error saving financial data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Financial Setup'),
        backgroundColor: const Color(0xFF6B5B95),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _incomeController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Monthly Income',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _savingsController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Monthly Savings Goal',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _emergencyController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Emergency Fund (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveFinancialData,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6B5B95),
              ),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}

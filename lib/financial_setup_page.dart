import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Theme Colors from ItemSelectionPage/DashboardPage
const Color _primaryColor = Color(0xFF008080); // Deep Teal
const Color _gradientStartColor = Color(0xFF2C3E50);
const Color _gradientEndColor = Color(0xFF4CA1AF);
const Color _cardColor = Color(0xFFFFFFFF);

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

  // Helper for themed text fields
  InputDecoration _buildInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.black54),
      filled: true,
      fillColor: _cardColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(color: _primaryColor, width: 2),
      ),
    );
  }

  Future<void> _saveFinancialData() async {
    // Basic validation
    if (_incomeController.text.isEmpty || _savingsController.text.isEmpty) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter Monthly Income and Savings Goal.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final currentUser = user;
    if (currentUser == null) return;

    try {
      final monthlyIncome = double.tryParse(_incomeController.text) ?? 0;
      final monthlySavingsGoal = double.tryParse(_savingsController.text) ?? 0;
      final emergencyFundGoal = double.tryParse(_emergencyController.text) ?? 0;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .set({
            'monthlyIncome': monthlyIncome,
            'monthlyBudget':
                monthlyIncome, // Assuming Monthly Income is the initial budget
            'savingsGoal': monthlySavingsGoal,
            'emergencyFundGoal': emergencyFundGoal,
            'initialBalance':
                monthlyIncome, // Set current balance to initial income
          }, SetOptions(merge: true));

      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Financial data saved successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      // ignore: use_build_context_synchronously
      Navigator.pop(context); // go back to profile page
    } catch (e) {
      debugPrint('Error saving financial data: $e');
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save data: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Financial Setup',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: _primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [_gradientStartColor, _gradientEndColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32.0),
            child: Card(
              elevation: 10,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Set Your Financial Foundation',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _incomeController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.black),
                      decoration: _buildInputDecoration('Monthly Income (₹)'),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _savingsController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.black),
                      decoration: _buildInputDecoration(
                        'Monthly Savings Goal (₹)',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _emergencyController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.black),
                      decoration: _buildInputDecoration(
                        'Emergency Fund Goal (₹) (Optional)',
                      ),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: _saveFinancialData,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Text(
                        'Save Financial Plan',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

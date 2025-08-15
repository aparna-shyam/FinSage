// main_app_page.dart
import 'package:flutter/material.dart';
import 'package:finsage/services/categorization_service.dart';

class MainAppPage extends StatefulWidget {
  const MainAppPage({super.key});

  @override
  State<MainAppPage> createState() => _MainAppPageState();
}

class _MainAppPageState extends State<MainAppPage> {
  final TextEditingController _transactionController = TextEditingController();
  String _categorizedResult = '';
  bool _isLoading = false;

  Future<void> _categorizeAndDisplay() async {
    final expenseDescription = _transactionController.text;
    if (expenseDescription.isEmpty) {
      return;
    }

    setState(() {
      _isLoading = true;
      _categorizedResult = '';
    });

    try {
      final category = await categorizeExpense(expenseDescription);
      setState(() {
        _categorizedResult = 'Category: $category';
      });
    } catch (e) {
      setState(() {
        _categorizedResult = 'Error: Failed to categorize transaction.';
        debugPrint('Categorization error: $e');
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _transactionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Welcome to FinSage!'),
        backgroundColor: const Color(0xFF6B5B95),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'Enter your expense to categorize:',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _transactionController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Expense description (e.g., "Coffee at Starbucks")',
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _categorizeAndDisplay,
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Categorize Expense'),
            ),
            const SizedBox(height: 20),
            if (_categorizedResult.isNotEmpty)
              Text(
                _categorizedResult,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF6B5B95),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

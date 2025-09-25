import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:finsage/item_selection_page.dart';

class BudgetPage extends StatefulWidget {
  const BudgetPage({super.key});

  @override
  State<BudgetPage> createState() => _BudgetPageState();
}

class _BudgetPageState extends State<BudgetPage> {
  User? get user => FirebaseAuth.instance.currentUser;

  final Map<String, double> _categoryBudgets = {};
  final Map<String, double> _categorySpent = {};

  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _budgetController = TextEditingController();

  @override
  void dispose() {
    _categoryController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  Future<void> _fetchBudgets() async {
    final currentUser = user;
    if (currentUser == null) return;

    // Fetch budgets from Firestore
    final budgetSnapshot = await FirebaseFirestore.instance
        .collection('budgets')
        .where('userId', isEqualTo: currentUser.uid)
        .get();

    final spendingSnapshot = await FirebaseFirestore.instance
        .collection('spending')
        .where('userId', isEqualTo: currentUser.uid)
        .get();

    setState(() {
      _categoryBudgets.clear();
      _categorySpent.clear();

      for (var doc in budgetSnapshot.docs) {
        final data = doc.data();
        _categoryBudgets[data['category']] =
            (data['budget'] as num?)?.toDouble() ?? 0.0;
      }

      for (var doc in spendingSnapshot.docs) {
        final data = doc.data();
        final category = data['category'] as String? ?? 'Others';
        final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
        _categorySpent[category] = (_categorySpent[category] ?? 0) + amount;
      }
    });
  }

  Future<void> _addBudget() async {
    final currentUser = user;
    if (currentUser == null) return;
    final category = _categoryController.text.trim();
    final amount = double.tryParse(_budgetController.text.trim()) ?? 0.0;

    if (category.isEmpty || amount <= 0) return;

    await FirebaseFirestore.instance.collection('budgets').add({
      'userId': currentUser.uid,
      'category': category,
      'budget': amount,
      'createdAt': FieldValue.serverTimestamp(),
    });

    _categoryController.clear();
    _budgetController.clear();

    _fetchBudgets();
    Navigator.pop(context);
  }

  void _showAddBudgetDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Budget'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _categoryController,
                decoration: const InputDecoration(labelText: 'Category'),
              ),
              TextField(
                controller: _budgetController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Budget Amount'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: _addBudget,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6B5B95),
              ),
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _fetchBudgets();
  }

  String _formatCurrency(double amount) {
    return NumberFormat.currency(locale: 'en_IN', symbol: '₹').format(amount);
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const Center(child: Text('Please log in to view your budget.'));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Budget'),
        backgroundColor: const Color(0xFF6B5B95),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _categoryBudgets.isEmpty
            ? const Center(
                child: Text(
                  'No budgets set. Click + to add one!',
                  style: TextStyle(fontSize: 18),
                ),
              )
            : ListView(
                children: _categoryBudgets.keys.map((category) {
                  final budget = _categoryBudgets[category] ?? 0.0;
                  final spent = _categorySpent[category] ?? 0.0;
                  final progress = spent / budget;

                  Color progressColor;
                  if (progress < 0.7) {
                    progressColor = Colors.green;
                  } else if (progress < 1) {
                    progressColor = Colors.orange;
                  } else {
                    progressColor = Colors.red;
                  }

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: ListTile(
                      title: Text(category),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          LinearProgressIndicator(
                            value: progress > 1 ? 1 : progress,
                            color: progressColor,
                            backgroundColor: Colors.grey[300],
                          ),
                          const SizedBox(height: 4),
                          Text(
                              'Spent: ${_formatCurrency(spent)} / Budget: ${_formatCurrency(budget)}'),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddBudgetDialog,
        backgroundColor: const Color(0xFF6B5B95),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

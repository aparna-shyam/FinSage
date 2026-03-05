import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import '../services/voice_input_service.dart';
import '../utils/voice_command_parser.dart';

const Color _primaryColor = Color(0xFF008080);
const Color _secondaryColor = Color(0xFFB76E79);
const Color _gradientStart = Color(0xFF2C3E50);
const Color _gradientEnd = Color(0xFF4CA1AF);
const Color _backgroundColor = Colors.transparent;
const Color _cardColor = Color(0xFFFFFFFF);

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

  final List<String> _categories = [
    'Food',
    'Transport',
    'Shopping',
    'Entertainment',
    'Bills',
    'Groceries',
    'Health',
    'Education',
    'Other',
  ];

  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _fetchBudgets();
  }

  @override
  void dispose() {
    _categoryController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  // ================= FETCH =================

  Future<void> _fetchBudgets() async {
    final currentUser = user;
    if (currentUser == null) return;

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
        final category = (data['category'] ?? 'other').toString().toLowerCase();
        final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
        _categorySpent[category] =
            (_categorySpent[category] ?? 0) + amount;
      }
    });
  }

  // ================= AI FEATURE =================

  Future<void> _generateAISuggestedBudget() async {
  final currentUser = user;
  if (currentUser == null) return;

  final now = DateTime.now();
  final oneYearAgo = DateTime(now.year - 1, now.month, now.day);

  final spendingSnapshot = await FirebaseFirestore.instance
      .collection('spending')
      .where('userId', isEqualTo: currentUser.uid)
      .where('date',
          isGreaterThanOrEqualTo: Timestamp.fromDate(oneYearAgo))
      .get();

  Map<String, double> categoryTotals = {};
  Map<String, Set<String>> categoryActiveMonths = {};

  for (var doc in spendingSnapshot.docs) {
    final data = doc.data();

    final category =
        (data['category'] ?? 'other').toString().toLowerCase();

    final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;

    if (data['date'] != null) {
      final Timestamp timestamp = data['date'];
      final DateTime date = timestamp.toDate();

      final monthKey = "${date.year}-${date.month}";

      categoryActiveMonths.putIfAbsent(category, () => {});
      categoryActiveMonths[category]!.add(monthKey);
    }

    categoryTotals[category] =
        (categoryTotals[category] ?? 0) + amount;
  }

  Map<String, double> suggestedBudgets = {};

  categoryTotals.forEach((category, totalSpent) {
    final activeMonths =
        categoryActiveMonths[category]?.length ?? 1;

    final monthlyAverage = totalSpent / activeMonths;

    suggestedBudgets[category] =
        monthlyAverage * 1.1; // 10% buffer
  });

  if (suggestedBudgets.isEmpty) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (_) => const AlertDialog(
        title: Text("AI Suggested Budget"),
        content: Text("No spending data found in last 1 year."),
      ),
    );
    return;
  }

  if (!mounted) return;

  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text("AI Suggested Budget (1-Year Smart Avg)"),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView(
          shrinkWrap: true,
          children: suggestedBudgets.entries.map((entry) {
            return ListTile(
              title: Text(entry.key.toUpperCase()),
              subtitle: Text(
                  "Based on ${categoryActiveMonths[entry.key]?.length ?? 1} active months"),
              trailing: Text(
                _formatCurrency(entry.value),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            );
          }).toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Close"),
        ),
      ],
    ),
  );
}
  // ================= ADD / UPDATE =================

  Future<void> _addBudget() async {
    final currentUser = user;
    if (currentUser == null) return;

    final category = _selectedCategory ?? _categoryController.text.trim();
    final amount =
        double.tryParse(_budgetController.text.trim()) ?? 0.0;

    if (category.isEmpty || amount <= 0) return;

    final existingBudget = await FirebaseFirestore.instance
        .collection('budgets')
        .where('userId', isEqualTo: currentUser.uid)
        .where('category', isEqualTo: category)
        .get();

    if (existingBudget.docs.isNotEmpty) {
      await FirebaseFirestore.instance
          .collection('budgets')
          .doc(existingBudget.docs.first.id)
          .update({'budget': amount});
    } else {
      await FirebaseFirestore.instance.collection('budgets').add({
        'userId': currentUser.uid,
        'category': category,
        'budget': amount,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    _categoryController.clear();
    _budgetController.clear();
    _selectedCategory = null;

    _fetchBudgets();
    Navigator.pop(context);
  }

  // ================= UI =================

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const Center(child: Text('Please log in.'));
    }

    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: const Text('My Current Budgets'),
        backgroundColor: _primaryColor,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_gradientStart, _gradientEnd],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: _categoryBudgets.isEmpty
              ? const Center(
                  child: Text(
                    'No budgets set yet.',
                    style: TextStyle(color: Colors.white),
                  ),
                )
              : ListView(
                  children: _categoryBudgets.keys.map((category) {
                    final budget =
                        _categoryBudgets[category] ?? 0.0;
                    final spent =
                        _categorySpent[category] ?? 0.0;
                    
                    final double progress =
                        budget > 0 ? (spent / budget) : 0.0;

                    return Card(
                      color: _cardColor,
                      margin:
                          const EdgeInsets.symmetric(vertical: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              category.toUpperCase(),
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            LinearProgressIndicator(
                              value: progress > 1 ? 1.0 : progress.toDouble(),
                            ),
                            const SizedBox(height: 8),
                            Text(
                                "Spent: ${_formatCurrency(spent)}"),
                            Text(
                                "Budget: ${_formatCurrency(budget)}"),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
        ),
      ),

      // ================= FLOATING BUTTONS =================

      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'ai_budget',
            onPressed: _generateAISuggestedBudget,
            backgroundColor: Colors.purple,
            child: const Icon(Icons.auto_awesome),
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            heroTag: 'add_budget',
            onPressed: () {
              _showAddBudgetDialog();
            },
            backgroundColor: _secondaryColor,
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }

  void _showAddBudgetDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Add Budget"),
        content: TextField(
          controller: _budgetController,
          keyboardType: TextInputType.number,
          decoration:
              const InputDecoration(labelText: "Amount"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: _addBudget,
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(double amount) {
    return NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
    ).format(amount);
  }
}
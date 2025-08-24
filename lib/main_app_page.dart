// main_app_page.dart
import 'package:flutter/material.dart';
import 'package:finsage/services/news_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:finsage/services/categorization_services.dart';

class MainAppPage extends StatefulWidget {
  const MainAppPage({super.key});

  @override
  State<MainAppPage> createState() => _MainAppPageState();
}

class _MainAppPageState extends State<MainAppPage> {
  final TextEditingController _transactionController = TextEditingController();
  String _categorizedResult = '';
  bool _isLoading = false;
  bool _receiveSuggestions = false;
  List<Map<String, String>> _financialNewsAndTips = [];
  List<String> _investmentSuggestions = [];
  List<Map<String, dynamic>> _transactionHistory = [];
  Map<String, double> _spendingSummary = {};

  @override
  void initState() {
    super.initState();
    _fetchUserPreferenceAndNewsAndSuggestions();
    _fetchTransactionHistory();
  }

  Future<void> _fetchUserPreferenceAndNewsAndSuggestions() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (userDoc.exists) {
        final data = userDoc.data();
        if (mounted) {
          setState(() {
            _receiveSuggestions = data?['receiveSuggestions'] ?? false;
          });
          if (_receiveSuggestions) {
            _fetchFinancialNewsAndTips();
            _fetchInvestmentSuggestions();
          }
        }
      }
    }
  }

  Future<void> _fetchFinancialNewsAndTips() async {
    final content = await NewsService().fetchFinancialNewsAndTips();
    if (mounted) {
      setState(() {
        _financialNewsAndTips = content;
      });
    }
  }

  Future<void> _fetchInvestmentSuggestions() async {
    final suggestions = await NewsService().fetchInvestmentSuggestions();
    if (mounted) {
      setState(() {
        _investmentSuggestions = suggestions;
      });
    }
  }

  Future<void> _fetchTransactionHistory() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('transactions')
          .orderBy('timestamp', descending: true)
          .limit(10)
          .get();

      final history = querySnapshot.docs.map((doc) => doc.data()).toList();
      _calculateSpendingSummary(history);

      if (mounted) {
        setState(() {
          _transactionHistory = history;
        });
      }
    } catch (e) {
      debugPrint('Error fetching transaction history: $e');
    }
  }

  void _calculateSpendingSummary(List<Map<String, dynamic>> transactions) {
    Map<String, double> summary = {};
    for (var transaction in transactions) {
      final category = transaction['category'] ?? 'Uncategorized';
      final amount = (transaction['amount'] as num?)?.toDouble() ?? 0.0;
      summary.update(
        category,
        (value) => value + amount,
        ifAbsent: () => amount,
      );
    }
    _spendingSummary = summary;
  }

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
      final amount = _extractAmountFromDescription(expenseDescription);

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('transactions')
            .add({
              'description': expenseDescription,
              'category': category,
              'amount': amount,
              'timestamp': FieldValue.serverTimestamp(),
            });
      }

      if (mounted) {
        setState(() {
          _categorizedResult = 'Category: $category';
        });
      }
      _fetchTransactionHistory();
      _transactionController.clear();
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

  double _extractAmountFromDescription(String description) {
    final regex = RegExp(r'\d+(\.\d+)?');
    final match = regex.firstMatch(description);
    if (match != null) {
      return double.tryParse(match.group(0)!) ?? 0.0;
    }
    return 0.0;
  }

  @override
  void dispose() {
    _transactionController.dispose();
    super.dispose();
  }

  Future<void> _launchUrl(String url) async {
    if (!await launchUrl(Uri.parse(url))) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not launch $url'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FinSage Dashboard'),
        backgroundColor: const Color(0xFF6B5B95),
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildCategorizationSection(), // Moved to the top
              const SizedBox(height: 20),
              if (_receiveSuggestions && _financialNewsAndTips.isNotEmpty)
                _buildNewsAndTipsCard(),
              if (_receiveSuggestions &&
                  _financialNewsAndTips.isNotEmpty &&
                  _investmentSuggestions.isNotEmpty)
                const SizedBox(height: 20),
              if (_receiveSuggestions && _investmentSuggestions.isNotEmpty)
                _buildInvestmentSuggestionsCard(),
              if (_transactionHistory.isNotEmpty) ...[
                const SizedBox(height: 20),
                _buildSpendingSummarySection(),
                const SizedBox(height: 20),
                _buildTransactionHistorySection(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // The rest of the build methods remain the same, but with new UI details.

  Widget _buildNewsAndTipsCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade100, Colors.lightGreen.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Card(
        color: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.lightbulb, color: Colors.green, size: 24),
                  SizedBox(width: 8),
                  Text(
                    'Financial Insights',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6B5B95),
                    ),
                  ),
                ],
              ),
              const Divider(color: Color(0xFF6B5B95), height: 20),
              ..._financialNewsAndTips.map(
                (item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: InkWell(
                    onTap: item['url'] != null && item['url']!.isNotEmpty
                        ? () => _launchUrl(item['url']!)
                        : null,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.star, size: 16, color: Colors.green),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            item['text']!,
                            style: TextStyle(
                              fontSize: 14,
                              decoration: item['url']!.isNotEmpty
                                  ? TextDecoration.underline
                                  : TextDecoration.none,
                              color: item['url']!.isNotEmpty
                                  ? Colors.blue[900]
                                  : Colors.black,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInvestmentSuggestionsCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade100, Colors.blue.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Card(
        color: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.trending_up, color: Colors.blue, size: 24),
                  SizedBox(width: 8),
                  Text(
                    'Investment Suggestions',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6B5B95),
                    ),
                  ),
                ],
              ),
              const Divider(color: Color(0xFF6B5B95), height: 20),
              ..._investmentSuggestions.map(
                (item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.arrow_right,
                        size: 16,
                        color: Colors.blue,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(item, style: const TextStyle(fontSize: 14)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategorizationSection() {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'Enter your expense to categorize:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _transactionController,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                labelText:
                    'Expense description (e.g., "Coffee at Starbucks for \$5")',
                prefixIcon: const Icon(Icons.shopping_cart),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _categorizeAndDisplay,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6B5B95),
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 15,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      'Categorize Expense',
                      style: TextStyle(color: Colors.white),
                    ),
            ),
            if (_categorizedResult.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text(
                _categorizedResult,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF6B5B95),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSpendingSummarySection() {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Spending Summary',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            const SizedBox(height: 10),
            ..._spendingSummary.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(entry.key, style: const TextStyle(fontSize: 16)),
                    Text(
                      '\$${entry.value.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionHistorySection() {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recent Transactions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            const SizedBox(height: 10),
            ..._transactionHistory.map((transaction) {
              final description = transaction['description'] ?? 'N/A';
              final category = transaction['category'] ?? 'N/A';
              final amount =
                  (transaction['amount'] as num?)?.toStringAsFixed(2) ?? '0.00';
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    const Icon(Icons.history, color: Colors.grey),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            description,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Category: $category',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '\$$amount',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}

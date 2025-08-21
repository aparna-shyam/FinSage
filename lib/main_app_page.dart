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

  @override
  void initState() {
    super.initState();
    _fetchUserPreferenceAndNewsAndSuggestions();
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
        title: const Text('Welcome to FinSage!'),
        backgroundColor: const Color(0xFF6B5B95),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              if (_receiveSuggestions && _financialNewsAndTips.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.lightGreen[100],
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.3),
                        spreadRadius: 2,
                        blurRadius: 5,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Financial Insights',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF6B5B95),
                        ),
                      ),
                      const Divider(color: Color(0xFF6B5B95)),
                      ..._financialNewsAndTips.map(
                        (item) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: InkWell(
                            onTap:
                                item['url'] != null && item['url']!.isNotEmpty
                                ? () => _launchUrl(item['url']!)
                                : null,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.star,
                                  size: 16,
                                  color: Colors.green,
                                ),
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
              if (_receiveSuggestions && _financialNewsAndTips.isNotEmpty)
                const SizedBox(height: 20),
              if (_receiveSuggestions && _investmentSuggestions.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.3),
                        spreadRadius: 2,
                        blurRadius: 5,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Investment Suggestions',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF6B5B95),
                        ),
                      ),
                      const Divider(color: Color(0xFF6B5B95)),
                      ..._investmentSuggestions.map(
                        (item) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.trending_up,
                                size: 16,
                                color: Colors.blue,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  item,
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              if (_receiveSuggestions && _investmentSuggestions.isNotEmpty)
                const SizedBox(height: 20),
              const Text(
                'Enter your expense to categorize:',
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _transactionController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText:
                      'Expense description (e.g., "Coffee at Starbucks")',
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
      ),
    );
  }
}

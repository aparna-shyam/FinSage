import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:finsage/item_selection_page.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:finsage/services/news_service.dart';

// Import the placeholder pages
import 'package:finsage/transactions_page.dart';
import 'package:finsage/budget_page.dart';
import 'package:finsage/goals_page.dart';
import 'package:finsage/profile_page.dart';
import 'package:finsage/spending_report_page.dart';
import 'package:finsage/insights_page.dart';
import 'package:finsage/category_selection_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    _DashboardHome(),
    const TransactionsPage(),
    const BudgetPage(),
    const GoalsPage(),
    const InsightsPage(),
    const ProfilePage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.swap_horiz),
            label: 'Transactions',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.pie_chart), label: 'Budget'),
          BottomNavigationBarItem(icon: Icon(Icons.star), label: 'Goals'),
          BottomNavigationBarItem(
            icon: Icon(Icons.insights),
            label: 'Insights',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFF6B5B95),
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
      ),
      // Only show FAB for Home (0) and Transactions (1) pages
      floatingActionButton: (_selectedIndex == 0 || _selectedIndex == 1)
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CategorySelectionPage(),
                  ),
                );
              },
              backgroundColor: const Color(0xFF6B5B95),
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null, // Hide FAB for other pages (Budget, Goals, Insights, Profile)
    );
  }
}

class _DashboardHome extends StatefulWidget {
  @override
  _DashboardHomeState createState() => _DashboardHomeState();
}

class _DashboardHomeState extends State<_DashboardHome> {
  String _userName = '';
  double _currentBalance = 0;
  double _totalSpent = 0;
  double _monthlyBudget = 15000;
  Map<String, double> _monthlySpending = {};
  List<Map<String, dynamic>> _recentTransactions = [];
  bool _isLoading = true;
  String _apiTip = "Loading daily tip...";

  User? get user => FirebaseAuth.instance.currentUser;
  final _newsService = NewsService();

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      // Fetch user profile data and monthly budget
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();
      
      double initialBalance = 0;
      
      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>? ?? {};
        _userName = data['name'] ?? 'User';
        _monthlyBudget = (data['monthlyBudget'] as num?)?.toDouble() ?? 15000;
        initialBalance = (data['initialBalance'] as num?)?.toDouble() ?? _monthlyBudget;
      }

      // Fetch current month's spending
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final spendingSnapshot = await FirebaseFirestore.instance
          .collection('spending')
          .where('userId', isEqualTo: currentUser.uid)
          .where('date', isGreaterThanOrEqualTo: startOfMonth)
          .get();

      double totalSpending = 0;
      for (var doc in spendingSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
        final category = data['category'] as String? ?? 'Other';
        totalSpending += amount;
        _monthlySpending.update(
          category,
          (val) => val + amount,
          ifAbsent: () => amount,
        );
      }
      
      _totalSpent = totalSpending;
      _currentBalance = initialBalance - totalSpending;

      // Fetch recent transactions
      final transactionsSnapshot = await FirebaseFirestore.instance
          .collection('spending')
          .where('userId', isEqualTo: currentUser.uid)
          .orderBy('date', descending: true)
          .limit(4)
          .get();
      _recentTransactions = transactionsSnapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();

      // Fetch financial tips and investment suggestions
      final tips = await _newsService.fetchFinancialNewsAndTips();
      if (tips.isNotEmpty) {
        _apiTip = tips.first['text'] ?? "Try setting up a budget!";
      }
    } catch (e) {
      debugPrint('Error fetching dashboard data: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _formatCurrency(double amount) {
    return NumberFormat.currency(locale: 'en_IN', symbol: '₹').format(amount);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDarkMode ? Colors.grey[850] : null;

    final sortedSpending = _monthlySpending.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topThreeCategories = sortedSpending.take(3);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {
            // You can open a drawer or add functionality
          },
        ),
        title: Text('Hello, $_userName!'),
        backgroundColor: const Color(0xFF6B5B95),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Notifications tapped')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Current Balance Card
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                color: cardColor,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        'Current Balance',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text(
                        _formatCurrency(_currentBalance),
                        style: Theme.of(context).textTheme.displaySmall,
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: _totalSpent / _monthlyBudget,
                        backgroundColor: Colors.grey.shade300,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Colors.green,
                        ),
                        minHeight: 10,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Spent this month: ${_formatCurrency(_totalSpent)} / ${_formatCurrency(_monthlyBudget)}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Budget Progress for top 3 categories
              Text(
                'Budget Progress (Top Categories)',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 10),
              ...topThreeCategories.map((entry) {
                final category = entry.key;
                final spent = entry.value;
                final budget = _monthlyBudget / topThreeCategories.length;
                final progress = budget > 0 ? spent / budget : 0.0;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: LinearPercentIndicator(
                    lineHeight: 16.0,
                    percent: progress > 1.0 ? 1.0 : progress,
                    backgroundColor: Colors.grey.shade300,
                    progressColor: progress > 1.0 ? Colors.red : Colors.purple,
                    barRadius: const Radius.circular(8),
                    center: Text(
                      "$category: ${_formatCurrency(spent)} / ${_formatCurrency(budget)}",
                      style: const TextStyle(fontSize: 12, color: Colors.white),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 20),

              // Recent Transactions
              Text(
                'Recent Transactions',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 10),
              if (_recentTransactions.isNotEmpty)
                ..._recentTransactions.map((transaction) {
                  final description = transaction['description'] ?? 'N/A';
                  final category = transaction['category'] ?? 'N/A';
                  final amount =
                      (transaction['amount'] as num?)?.toDouble() ?? 0.0;
                  final timestamp = (transaction['date'] as Timestamp).toDate();
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: cardColor,
                    child: ListTile(
                      title: Text(
                        description,
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        '$category - ${DateFormat('MMM d, y').format(timestamp)}',
                      ),
                      trailing: Text(
                        _formatCurrency(amount),
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(color: Colors.redAccent),
                      ),
                    ),
                  );
                }),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
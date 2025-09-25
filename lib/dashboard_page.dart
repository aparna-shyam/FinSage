import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:finsage/item_selection_page.dart';

// Import the new placeholder pages
import 'package:finsage/transactions_page.dart';
import 'package:finsage/budget_page.dart';
import 'package:finsage/goals_page.dart';
import 'package:finsage/profile_page.dart';
import 'package:finsage/spending_report_page.dart';

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
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.swap_horiz), label: 'Transactions'),
          BottomNavigationBarItem(icon: Icon(Icons.pie_chart), label: 'Budget'),
          BottomNavigationBarItem(icon: Icon(Icons.star), label: 'Goals'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFF6B5B95),
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
      ),
      floatingActionButton: _selectedIndex == 1
          ? FloatingActionButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) {
                    return SimpleDialog(
                      title: const Text('Select Category'),
                      children: [
                        ...[
                          'Grocery',
                          'Medicines',
                          'Food',
                          'Drinks',
                          'Bill Payments',
                          'Apparel',
                          'Electronics',
                          'Cosmetics',
                          'Sports',
                          'Stationary',
                          'Books',
                        ].map((category) {
                          return SimpleDialogOption(
                            child: Text(category),
                            onPressed: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ItemSelectionPage(category: category),
                                ),
                              );
                            },
                          );
                        }).toList(),
                      ],
                    );
                  },
                );
              },
              backgroundColor: const Color(0xFF6B5B95),
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
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
  List<Map<String, dynamic>> _recentTransactions = [];
  Map<String, double> _budgetGoals = {}; // category -> goal
  Map<String, double> _spentInCategory = {}; // category -> spent
  bool _isLoading = true;

  User? get user => FirebaseAuth.instance.currentUser;

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
      // Fetch user profile
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();
      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>? ?? {};
        _userName = data['name'] ?? 'User';
        final budgetMap = data['budgetGoals'] as Map<String, dynamic>? ?? {};
        _budgetGoals = budgetMap.map((k, v) => MapEntry(k, (v as num).toDouble()));
      }

      // Fetch spending
      final spendingSnapshot = await FirebaseFirestore.instance
          .collection('spending')
          .where('userId', isEqualTo: currentUser.uid)
          .get();

      _currentBalance = 0;
      _spentInCategory = {};

      for (var doc in spendingSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final amount = (data['amount'] as num?)?.toDouble() ?? 0;
        final category = data['category'] as String? ?? 'Other';
        _currentBalance += amount;
        _spentInCategory.update(category, (value) => value + amount, ifAbsent: () => amount);
      }

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
    } catch (e) {
      debugPrint('Error fetching dashboard data: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatCurrency(double amount) {
    return NumberFormat.currency(locale: 'en_IN', symbol: '₹').format(amount);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return Scaffold(
      appBar: AppBar(
        title: Text('Hello, $_userName!'),
        backgroundColor: const Color(0xFF6B5B95),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SpendingReportPage()),
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
              // Balance Card
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text('Current Balance', style: Theme.of(context).textTheme.titleLarge),
                      Text(_formatCurrency(_currentBalance),
                          style: Theme.of(context).textTheme.displaySmall),
                      const SizedBox(height: 8),
                      Text('Available vs Reserved: ${_formatCurrency(_currentBalance * 0.8)} / ${_formatCurrency(_currentBalance * 0.2)}',
                          style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Budget Goals
              Text('Budget Progress', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 10),
              ..._budgetGoals.keys.map((category) {
                final budget = _budgetGoals[category]!;
                final spent = _spentInCategory[category] ?? 0;
                final progress = spent / budget;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$category: ${_formatCurrency(spent)} / ${_formatCurrency(budget)}'),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: progress.toDouble(), // cast to double
                      color: Colors.purple,
                      backgroundColor: Colors.grey.shade300,
                      minHeight: 8,
                    ),
                    const SizedBox(height: 10),
                  ],
                );
              }).toList(),

              const SizedBox(height: 20),

              // Recent Transactions
              Text('Recent Transactions', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 10),
              if (_recentTransactions.isNotEmpty)
                ..._recentTransactions.map((transaction) {
                  final description = transaction['description'] as String? ?? 'N/A';
                  final category = transaction['category'] as String? ?? 'N/A';
                  final amount = (transaction['amount'] as num?)?.toDouble() ?? 0;
                  final timestamp = transaction['date'] as Timestamp;

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: ListTile(
                      title: Text(description),
                      subtitle: Text('$category - ${DateFormat('MMM d, y').format(timestamp.toDate())}'),
                      trailing: Text(_formatCurrency(amount), style: Theme.of(context).textTheme.titleMedium),
                    ),
                  );
                }).toList()
              else
                const Center(child: Text('No recent transactions.')),

              const SizedBox(height: 20),
              // Daily tip placeholder
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    'Tip: Try to reduce soda consumption this week!',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

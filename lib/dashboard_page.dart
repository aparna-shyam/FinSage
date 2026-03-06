import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/percent_indicator.dart';

// 👈 IMPORTANT: Import the actual chatbot file
import 'package:finsage/chatbot_page.dart';

// Original Imports
import 'package:finsage/transactions_page.dart';
import 'package:finsage/budget_page.dart';
import 'package:finsage/goals_page.dart';
import 'package:finsage/profile_page.dart';
import 'package:finsage/insights_page.dart';
import 'package:finsage/category_selection_page.dart';
import 'package:finsage/recurring_payments.dart';

// Theme Colors
const Color _primaryColor = Color(0xFF008080);
const Color _secondaryColor = Color(0xFFB76E79);
const Color _gradientStartColor = Color(0xFF2C3E50);
const Color _gradientEndColor = Color(0xFF4CA1AF);
const Color _cardColor = Color(0xFFFFFFFF);

final GlobalKey<_DashboardHomeState> _dashboardHomeKey =
    GlobalKey<_DashboardHomeState>();

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});
  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    _DashboardHome(key: _dashboardHomeKey),
    const TransactionsPage(),
    const RecurringPaymentsPage(),
    const BudgetPage(),
    const GoalsPage(),
    const InsightsPage(),
    const ChatBotPage(), // 👈 Points to chatbot_page.dart
    const ProfilePage(),
  ];

  final List<String> _pageTitles = const [
    'Home',
    'Transactions',
    'Recurring Payments',
    'Budget',
    'Goals',
    'Insights',
    'Chat with Bodhi',
    'Profile',
  ];

  final List<IconData> _pageIcons = const [
    Icons.home,
    Icons.swap_horiz,
    Icons.autorenew,
    Icons.pie_chart,
    Icons.star,
    Icons.insights,
    Icons.smart_toy,
    Icons.person,
  ];

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _selectedIndex == 0
            ? const _DashboardHomeTitle()
            : Text(
                _pageTitles[_selectedIndex],
                style: const TextStyle(color: Colors.white),
              ),
        backgroundColor: _primaryColor,
      ),
      drawer: Drawer(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [_gradientStartColor, _gradientEndColor],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Image.asset(
                      'assets/bodhi/casual.png',
                      height: 60,
                      width: 60,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'FinSage Menu',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              ...List.generate(
                _pages.length,
                (index) => ListTile(
                  leading: Icon(
                    _pageIcons[index],
                    color: _selectedIndex == index
                        ? _secondaryColor
                        : Colors.white70,
                  ),
                  title: Text(
                    _pageTitles[index],
                    style: TextStyle(
                      color: _selectedIndex == index
                          ? _secondaryColor
                          : Colors.white,
                    ),
                  ),
                  onTap: () => _onItemTapped(index),
                ),
              ),
            ],
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [_gradientStartColor, _gradientEndColor],
          ),
        ),
        child: IndexedStack(index: _selectedIndex, children: _pages),
      ),
      floatingActionButton: (_selectedIndex == 0 || _selectedIndex == 1)
          ? FloatingActionButton(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CategorySelectionPage(),
                  ),
                );
                if (_selectedIndex == 0)
                  _dashboardHomeKey.currentState?.refreshData();
              },
              backgroundColor: _secondaryColor,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }
}

// --- ALL YOUR ORIGINAL FEATURES BELOW ---

class _DashboardHomeTitle extends StatefulWidget {
  const _DashboardHomeTitle();
  @override
  State<_DashboardHomeTitle> createState() => _DashboardHomeTitleState();
}

class _DashboardHomeTitleState extends State<_DashboardHomeTitle> {
  String _userName = 'User';
  @override
  void initState() {
    super.initState();
    _fetchUserName();
  }

  Future<void> _fetchUserName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (mounted && doc.exists)
        setState(() => _userName = doc['name'] ?? 'User');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      'Hello, $_userName!',
      style: const TextStyle(color: Colors.white),
    );
  }
}

class _DashboardHome extends StatefulWidget {
  const _DashboardHome({super.key});
  @override
  _DashboardHomeState createState() => _DashboardHomeState();
}

class _DashboardHomeState extends State<_DashboardHome> {
  double _currentBalance = 0;
  double _totalSpent = 0;
  double _monthlyBudget = 15000;
  final Map<String, double> _monthlySpending = {};
  Map<String, List<Map<String, dynamic>>> _groupedTransactions = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    refreshData();
  }

  Future<void> refreshData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      setState(() => _isLoading = true);
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (userDoc.exists)
        _monthlyBudget =
            (userDoc['monthlyBudget'] as num?)?.toDouble() ?? 15000;

      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final spendingSnapshot = await FirebaseFirestore.instance
          .collection('spending')
          .where('userId', isEqualTo: user.uid)
          .where('date', isGreaterThanOrEqualTo: startOfMonth)
          .get();

      double total = 0;
      _monthlySpending.clear();
      for (var doc in spendingSnapshot.docs) {
        final amt = (doc['amount'] as num).toDouble();
        final cat = doc['category'] ?? 'Other';
        total += amt;
        _monthlySpending.update(cat, (v) => v + amt, ifAbsent: () => amt);
      }

      final recentSnapshot = await FirebaseFirestore.instance
          .collection('spending')
          .where('userId', isEqualTo: user.uid)
          .orderBy('date', descending: true)
          .limit(10)
          .get();

      _totalSpent = total;
      _currentBalance = _monthlyBudget - total;
      _groupedTransactions = _groupTransactionsByDate(
        recentSnapshot.docs.map((d) => d.data()).toList(),
      );
    } catch (e) {
      debugPrint("Error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Map<String, List<Map<String, dynamic>>> _groupTransactionsByDate(
    List<Map<String, dynamic>> txs,
  ) {
    Map<String, List<Map<String, dynamic>>> grouped = {};
    for (var tx in txs) {
      final date = DateFormat(
        'EEEE, d MMMM yyyy',
      ).format((tx['date'] as Timestamp).toDate());
      grouped.putIfAbsent(date, () => []).add(tx);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading)
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    final topThree =
        (_monthlySpending.entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value)))
            .take(3);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            color: _cardColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text('Current Balance', style: TextStyle(fontSize: 18)),
                  Text(
                    '₹${_currentBalance.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: _totalSpent / _monthlyBudget,
                    color: Colors.green,
                    backgroundColor: Colors.grey[300],
                  ),
                  Text('Spent: ₹$_totalSpent / ₹$_monthlyBudget'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Budget Progress',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          ...topThree.map(
            (e) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: LinearPercentIndicator(
                lineHeight: 16,
                percent: (e.value / (_monthlyBudget / 3)).clamp(0, 1),
                center: Text(
                  "${e.key}: ₹${e.value}",
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
                progressColor: _primaryColor,
                backgroundColor: Colors.white24,
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Recent Transactions',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          ..._groupedTransactions.entries.map(
            (group) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    group.key,
                    style: const TextStyle(color: Colors.white70),
                  ),
                ),
                ...group.value.map(
                  (tx) => Card(
                    child: ListTile(
                      title: Text(tx['description'] ?? ''),
                      trailing: Text(
                        '₹${tx['amount']}',
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

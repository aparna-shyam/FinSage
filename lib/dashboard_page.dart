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

// ⭐️ NEW IMPORT for Recurring Payments page (Placeholder) ⭐️
import 'package:finsage/recurring_payments.dart';

// 🍊 Define the Orange color for the theme
const Color _orangeColor = Color(0xFFD9641E);
// 💡 Define the Light Background color for the page body
const Color _lightBackgroundColor = Color(0xFFECE2D2);

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _selectedIndex = 0;

  // 1. Add the new page to the list of pages
  final List<Widget> _pages = [
    _DashboardHome(),
    const TransactionsPage(),
    const RecurringPaymentsPage(), // ⭐️ NEW: Recurring Payments Page ⭐️
    const BudgetPage(),
    const GoalsPage(),
    const InsightsPage(),
    const ProfilePage(),
  ];

  // 2. Add the title for the new page
  final List<String> _pageTitles = const [
    'Home',
    'Transactions',
    'Recurring Payments', // ⭐️ NEW Title ⭐️
    'Budget',
    'Goals',
    'Insights',
    'Profile',
  ];

  // 3. Add the icon for the new page
  final List<IconData> _pageIcons = const [
    Icons.home,
    Icons.swap_horiz,
    Icons.autorenew, // ⭐️ NEW Icon (e.g., Autorenew) ⭐️
    Icons.pie_chart,
    Icons.star,
    Icons.insights,
    Icons.person,
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    // Close the drawer after selection
    Navigator.pop(context);
  }

  // ⭐️ Updated Widget for the Navigation Drawer ⭐️
  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: _lightBackgroundColor,
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          // Header using the Orange theme color
          const DrawerHeader(
            decoration: BoxDecoration(color: _orangeColor),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'FinSage Menu',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Navigate your finances',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
          // List of navigation items
          ...List.generate(_pages.length, (index) {
            return ListTile(
              leading: Icon(
                _pageIcons[index],
                color: _selectedIndex == index ? _orangeColor : Colors.black87,
              ),
              title: Text(
                _pageTitles[index],
                style: TextStyle(
                  color: _selectedIndex == index
                      ? _orangeColor
                      : Colors.black87,
                  fontWeight: _selectedIndex == index
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
              onTap: () => _onItemTapped(index),
            );
          }),

          // Divider and Sign Out option (Example of extra menu item)
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.grey),
            title: const Text('Sign Out'),
            onTap: () {
              // Add sign out logic here
              FirebaseAuth.instance.signOut();
              Navigator.pop(context);
              // You might want to navigate to a login page here
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // The index of Recurring Payments is 2.
    // We explicitly exclude it from showing the app-wide FAB.
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _pages),

      // ⭐️ Add the Navigation Drawer ⭐️
      drawer: _buildDrawer(),

      // Removed BottomNavigationBar completely

      // Only show FAB for Home (0) and Transactions (1).
      floatingActionButton:
          (_selectedIndex == 0 || _selectedIndex == 1) // Logic to show/hide FAB
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CategorySelectionPage(),
                  ),
                );
              },
              backgroundColor: _orangeColor,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null, // Hide FAB for other pages
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
  final Map<String, double> _monthlySpending = {};
  Map<String, List<Map<String, dynamic>>> _groupedTransactions = {};
  bool _isLoading = true;
  String _apiTip = "Loading daily tip...";

  User? get user => FirebaseAuth.instance.currentUser;
  final _newsService = NewsService();

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  // ⭐️ New grouping function ⭐️
  Map<String, List<Map<String, dynamic>>> _groupTransactionsByDate(
    List<Map<String, dynamic>> transactions,
  ) {
    Map<String, List<Map<String, dynamic>>> grouped = {};
    // Format: 'EEEE, d MMMM yyyy' (e.g., 'Sunday, 12 October 2025')
    final DateFormat formatter = DateFormat('EEEE, d MMMM yyyy');

    for (var transaction in transactions) {
      final date = (transaction['date'] as Timestamp).toDate();
      final dateKey = formatter.format(date);

      if (!grouped.containsKey(dateKey)) {
        grouped[dateKey] = [];
      }
      grouped[dateKey]!.add(transaction);
    }
    return grouped;
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
        initialBalance =
            (data['initialBalance'] as num?)?.toDouble() ?? _monthlyBudget;
      }

      // Define date range for recent transactions (last 7 days)
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);

      // 🌟 Define start of 7-day filter 🌟
      final sevenDaysAgo = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(const Duration(days: 7));

      // Fetch current month's spending (used for budget progress)
      final spendingSnapshot = await FirebaseFirestore.instance
          .collection('spending')
          .where('userId', isEqualTo: currentUser.uid)
          .where('date', isGreaterThanOrEqualTo: startOfMonth)
          .get();

      double totalSpending = 0;
      for (var doc in spendingSnapshot.docs) {
        final data = doc.data();
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

      // Fetch recent transactions (last 7 days)
      final recentTransactionsSnapshot = await FirebaseFirestore.instance
          .collection('spending')
          .where('userId', isEqualTo: currentUser.uid)
          // 🌟 Filter by last 7 days 🌟
          .where('date', isGreaterThanOrEqualTo: sevenDaysAgo)
          .orderBy('date', descending: true)
          .get();

      final recentTransactions = recentTransactionsSnapshot.docs
          .map((doc) => doc.data())
          .toList();

      // 🌟 Group transactions by date 🌟
      _groupedTransactions = _groupTransactionsByDate(recentTransactions);

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

  // ⭐️ Widget to build the Date Header
  Widget _buildDateHeader(String dateKey) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 16, 0, 8),
      child: Text(
        dateKey,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: _orangeColor,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDarkMode ? Colors.grey[850] : null;

    final sortedSpending = _monthlySpending.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topThreeCategories = sortedSpending.take(3);

    // Create a list of widgets from the grouped data (Headers + Tiles)
    final List<Widget> datedTransactionList = [];
    final sortedDateKeys = _groupedTransactions.keys.toList()
      ..sort(
        (a, b) => DateFormat(
          'EEEE, d MMMM yyyy',
        ).parse(b).compareTo(DateFormat('EEEE, d MMMM yyyy').parse(a)),
      );

    for (var dateKey in sortedDateKeys) {
      final dateTransactions = _groupedTransactions[dateKey]!;
      // Add the date header (e.g., 'Sunday, 12 October 2025')
      datedTransactionList.add(_buildDateHeader(dateKey));

      // Add all transactions for that date
      datedTransactionList.addAll(
        dateTransactions.map((transaction) {
          final description = transaction['description'] ?? 'N/A';
          final category = transaction['category'] ?? 'N/A';
          final amount = (transaction['amount'] as num?)?.toDouble() ?? 0.0;

          return Card(
            margin: const EdgeInsets.symmetric(vertical: 4),
            color: cardColor,
            child: ListTile(
              title: Text(
                description,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(category), // Date removed, as it's in the header
              trailing: Text(
                _formatCurrency(amount),
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(color: Colors.redAccent),
              ),
            ),
          );
        }),
      );
    }

    return Scaffold(
      // ➡️ Scaffold background set to Light Beige
      backgroundColor: _lightBackgroundColor,
      appBar: AppBar(
        // Remove leading IconButton here; it's automatically handled by Scaffold.drawer
        title: Text(
          'Hello, $_userName!',
          style: const TextStyle(color: Colors.white),
        ),
        // ➡️ AppBar background orange
        backgroundColor: _orangeColor,
        automaticallyImplyLeading:
            true, // Set to true to automatically show hamburger icon
        // ❌ REMOVED: The actions list that contained the notification bell icon.
        actions: const [],
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
                // Simple assumption: divide total budget among top categories
                final budget = _monthlyBudget / topThreeCategories.length;
                final progress = budget > 0 ? spent / budget : 0.0;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: LinearPercentIndicator(
                    lineHeight: 16.0,
                    percent: progress > 1.0 ? 1.0 : progress,
                    backgroundColor: Colors.grey.shade300,
                    progressColor: progress > 1.0 ? Colors.red : _orangeColor,
                    barRadius: const Radius.circular(8),
                    center: Text(
                      "$category: ${_formatCurrency(spent)} / ${_formatCurrency(budget)}",
                      style: const TextStyle(fontSize: 12, color: Colors.black),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 20),

              // Recent Transactions (Date-grouped)
              Text(
                'Recent Transactions (Last 7 Days)',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              if (_groupedTransactions.isNotEmpty)
                ...datedTransactionList
              else
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Center(
                    child: Text(
                      'No transactions found in the last 7 days.',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

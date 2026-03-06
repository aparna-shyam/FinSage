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
import 'package:finsage/insights_page.dart';
import 'package:finsage/category_selection_page.dart';
import 'package:finsage/recurring_payments.dart';

// 💠 Theme Colors
const Color _primaryColor = Color(0xFF008080); // Deep Teal
const Color _secondaryColor = Color(0xFFB76E79); // Rose Gold
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

  // 1. Updated List of Pages (Added ChatBotPage)
  final List<Widget> _pages = [
    _DashboardHome(key: _dashboardHomeKey),
    const TransactionsPage(),
    const RecurringPaymentsPage(),
    const BudgetPage(),
    const GoalsPage(),
    const InsightsPage(),
    const ChatBotPage(), // ⭐ NEW
    const ProfilePage(),
  ];

  // 2. Updated Titles (Added FinSage AI)
  final List<String> _pageTitles = const [
    'Home',
    'Transactions',
    'Recurring Payments',
    'Budget',
    'Goals',
    'Insights',
    'FinSage AI', // ⭐ NEW
    'Profile',
  ];

  // 3. Updated Icons (Added Robot Icon)
  final List<IconData> _pageIcons = const [
    Icons.home,
    Icons.swap_horiz,
    Icons.autorenew,
    Icons.pie_chart,
    Icons.star,
    Icons.insights,
    Icons.smart_toy, // ⭐ NEW
    Icons.person,
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    Navigator.pop(context);
  }

  Widget _buildDrawer() {
    return Drawer(
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
          children: <Widget>[
            DrawerHeader(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8.0),
                    child: Image.asset(
                      'assets/bodhi/casual.png',
                      height: 60,
                      width: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.image,
                          size: 60,
                          color: Colors.white70,
                        );
                      },
                    ),
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
                  const Text(
                    'Financial Wisdom, Daily...',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
            ...List.generate(_pages.length, (index) {
              return ListTile(
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
                    fontWeight: _selectedIndex == index
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
                onTap: () => _onItemTapped(index),
              );
            }),
          ],
        ),
      ),
    );
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
        automaticallyImplyLeading: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [_gradientStartColor, _gradientEndColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: IndexedStack(index: _selectedIndex, children: _pages),
      ),
      drawer: _buildDrawer(),
      floatingActionButton: (_selectedIndex == 0 || _selectedIndex == 1)
          ? FloatingActionButton(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CategorySelectionPage(),
                  ),
                );
                if (_selectedIndex == 0 &&
                    _dashboardHomeKey.currentState != null) {
                  _dashboardHomeKey.currentState!.refreshData();
                }
              },
              backgroundColor: _secondaryColor,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }
}

// --- Dashboard Logic & Widgets ---

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
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();
      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>? ?? {};
        if (mounted) setState(() => _userName = data['name'] ?? 'User');
      }
    } catch (e) {
      if (mounted) setState(() => _userName = 'User');
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
  final _newsService = NewsService();

  Future<void> refreshData() async => await _fetchDashboardData();

  @override
  void initState() {
    super.initState();
    refreshData();
  }

  Future<void> _fetchDashboardData() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    try {
      if (mounted) setState(() => _isLoading = true);

      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();
      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>? ?? {};
        _monthlyBudget = (data['monthlyBudget'] as num?)?.toDouble() ?? 15000;
      }

      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final sevenDaysAgo = now.subtract(const Duration(days: 7));

      final spendingSnapshot = await FirebaseFirestore.instance
          .collection('spending')
          .where('userId', isEqualTo: currentUser.uid)
          .where('date', isGreaterThanOrEqualTo: startOfMonth)
          .get();

      double totalSpending = 0;
      _monthlySpending.clear();
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
      _currentBalance = _monthlyBudget - totalSpending;

      final recentTransactionsSnapshot = await FirebaseFirestore.instance
          .collection('spending')
          .where('userId', isEqualTo: currentUser.uid)
          .where('date', isGreaterThanOrEqualTo: sevenDaysAgo)
          .orderBy('date', descending: true)
          .get();

      final recentTransactions = recentTransactionsSnapshot.docs
          .map((doc) => doc.data())
          .toList();
      _groupedTransactions = _groupTransactionsByDate(recentTransactions);
    } catch (e) {
      debugPrint('Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Map<String, List<Map<String, dynamic>>> _groupTransactionsByDate(
    List<Map<String, dynamic>> transactions,
  ) {
    Map<String, List<Map<String, dynamic>>> grouped = {};
    final DateFormat formatter = DateFormat('EEEE, d MMMM yyyy');
    for (var tx in transactions) {
      final dateKey = formatter.format((tx['date'] as Timestamp).toDate());
      grouped.putIfAbsent(dateKey, () => []).add(tx);
    }
    return grouped;
  }

  String _formatCurrency(double amount) =>
      NumberFormat.currency(locale: 'en_IN', symbol: '₹').format(amount);

  @override
  Widget build(BuildContext context) {
    if (_isLoading)
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );

    final topThreeCategories =
        (_monthlySpending.entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value)))
            .take(3);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            color: _cardColor,
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
                    backgroundColor: Colors.grey.shade400,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.green,
                    ),
                    minHeight: 10,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Spent: ${_formatCurrency(_totalSpent)} / ${_formatCurrency(_monthlyBudget)}',
                  ),
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
          const SizedBox(height: 10),
          ...topThreeCategories.map((entry) {
            final progress = entry.value / (_monthlyBudget / 3);
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: LinearPercentIndicator(
                lineHeight: 16.0,
                percent: progress > 1.0 ? 1.0 : progress,
                backgroundColor: Colors.white30,
                progressColor: progress > 1.0 ? Colors.red : _primaryColor,
                barRadius: const Radius.circular(8),
                center: Text(
                  "${entry.key}: ${_formatCurrency(entry.value)}",
                  style: const TextStyle(fontSize: 12, color: Colors.white),
                ),
              ),
            );
          }),
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
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    group.key,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ...group.value.map(
                  (tx) => Card(
                    color: _cardColor,
                    child: ListTile(
                      title: Text(
                        tx['description'] ?? 'N/A',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(tx['category'] ?? 'N/A'),
                      trailing: Text(
                        _formatCurrency((tx['amount'] as num).toDouble()),
                        style: const TextStyle(
                          color: Colors.redAccent,
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

// ⭐ NEW: ChatBot Page Placeholder
class ChatBotPage extends StatelessWidget {
  const ChatBotPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.smart_toy, size: 80, color: Colors.white70),
          SizedBox(height: 16),
          Text(
            'FinSage AI Assistant',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          Padding(
            padding: EdgeInsets.all(20.0),
            child: Text(
              'Ask me anything about your spending or financial goals!',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }
}

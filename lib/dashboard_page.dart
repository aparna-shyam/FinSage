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

// ⭐️ NEW IMPORT for Recurring Payments page ⭐️
import 'package:finsage/recurring_payments.dart';

// 💠 Define the Primary/Accent color: Deep Teal ⭐️
const Color _primaryColor = Color(0xFF008080);
// 🌹 Define the Secondary color: Rose Gold ⭐️
const Color _secondaryColor = Color(0xFFB76E79);

// 🔵 Gradient Start Color: Dark Blue-Purple
const Color _gradientStartColor = Color(0xFF2C3E50);
// 🔷 Gradient End Color: Lighter Blue-Teal
const Color _gradientEndColor = Color(0xFF4CA1AF);

// ⬜ Define the Card/Box color: Pure White ⭐️
const Color _cardColor = Color(0xFFFFFFFF);

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _selectedIndex = 0;

  // 1. Add the new page to the list of pages
  // FIX: Removed 'const' keyword where necessary to avoid constructor errors.
  final List<Widget> _pages = [
    _DashboardHome(),
    const TransactionsPage(),
    const RecurringPaymentsPage(),
    const BudgetPage(),
    const GoalsPage(),
    const InsightsPage(),
    const ProfilePage(),
  ];

  // 2. Add the title for the new page
  final List<String> _pageTitles = const [
    'Home',
    'Transactions',
    'Recurring Payments',
    'Budget',
    'Goals',
    'Insights',
    'Profile',
  ];

  // 3. Add the icon for the new page
  final List<IconData> _pageIcons = const [
    Icons.home,
    Icons.swap_horiz,
    Icons.autorenew,
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

  // ⭐️ Updated Widget for the Navigation Drawer with Gradient Background and Mascot Image ⭐️
  Widget _buildDrawer() {
    return Drawer(
      // The drawer itself needs a gradient background
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
            // Header for the Drawer
            DrawerHeader(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // ⭐️ MASCOT IMAGE WIDGET ⭐️
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8.0),
                    child: Image.asset(
                      'assets/bodhi/casual.png', // Your image path
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
                  const SizedBox(height: 4),
                  const Text(
                    'Financial Wisdom, Daily...',
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
                  color: _selectedIndex == index
                      ? _secondaryColor
                      : Colors
                            .white70, // Rose Gold for selected, white for others
                ),
                title: Text(
                  _pageTitles[index],
                  style: TextStyle(
                    color: _selectedIndex == index
                        ? _secondaryColor
                        : Colors
                              .white, // Rose Gold for selected, white for others
                    fontWeight: _selectedIndex == index
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
                onTap: () => _onItemTapped(index),
              );
            }),

            // Divider and Sign Out option (Example of extra menu item)
            const Divider(
              color: Colors.white54,
            ), // Lighter divider for dark background
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.white70),
              title: const Text(
                'Sign Out',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                FirebaseAuth.instance.signOut();
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to wrap DashboardHome content in the gradient
  Widget _buildDashboardHomeWithGradient() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_gradientStartColor, _gradientEndColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      // We use the actual _DashboardHome widget here, which builds the content
      child: _pages[0],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Determine the page to display in the body
    Widget bodyContent;
    if (_selectedIndex == 0) {
      bodyContent = _buildDashboardHomeWithGradient();
    } else {
      // For other pages, display them normally (their Scaffolds will handle colors/backgrounds)
      bodyContent = IndexedStack(index: _selectedIndex, children: _pages);
    }

    return Scaffold(
      // AppBar uses the primary color (Deep Teal)
      appBar: AppBar(
        // 🚨 FIX for AppBar Title: Use _DashboardHomeTitle widget to get the username asynchronously
        title: _selectedIndex == 0
            ? const _DashboardHomeTitle()
            : Text(
                _pageTitles[_selectedIndex],
                style: const TextStyle(color: Colors.white),
              ),
        backgroundColor: _primaryColor,
        automaticallyImplyLeading: true,
        actions: const [],
      ),

      body: bodyContent,

      // Drawer must be placed directly inside the Scaffold.
      drawer: _buildDrawer(),

      // FAB must be placed directly inside the Scaffold.
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
              backgroundColor: _secondaryColor, // Rose Gold for FAB
              child: const Icon(
                Icons.add,
                color: Colors.white,
              ), // White icon for contrast on Rose Gold
            )
          : null,
    );
  }
}

// ⭐️ NEW Widget to handle asynchronous user name fetching for the AppBar title ⭐️
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
        final name = data['name'] ?? 'User';
        if (mounted) {
          setState(() {
            _userName = name;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _userName = 'User'; // Fallback
        });
      }
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

  Map<String, List<Map<String, dynamic>>> _groupTransactionsByDate(
    List<Map<String, dynamic>> transactions,
  ) {
    Map<String, List<Map<String, dynamic>>> grouped = {};
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

      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final sevenDaysAgo = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(const Duration(days: 7));

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
      // FIX: Current balance should be monthly budget minus total spent
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

  // ⭐️ Widget to build the Date Header (Text color changed to white/light for contrast)
  Widget _buildDateHeader(String dateKey) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 16, 0, 8),
      child: Text(
        dateKey,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.white, // Text color on gradient background
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    const Color cardColor = _cardColor; // Pure White
    const Color textColor = Colors.black; // Text color on white cards

    final sortedSpending = _monthlySpending.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topThreeCategories = sortedSpending.take(3);

    final List<Widget> datedTransactionList = [];
    final sortedDateKeys = _groupedTransactions.keys.toList()
      ..sort(
        (a, b) => DateFormat(
          'EEEE, d MMMM yyyy',
        ).parse(b).compareTo(DateFormat('EEEE, d MMMM yyyy').parse(a)),
      );

    for (var dateKey in sortedDateKeys) {
      final dateTransactions = _groupedTransactions[dateKey]!;
      datedTransactionList.add(_buildDateHeader(dateKey));

      datedTransactionList.addAll(
        dateTransactions.map((transaction) {
          final description = transaction['description'] ?? 'N/A';
          final category = transaction['category'] ?? 'N/A';
          final amount = (transaction['amount'] as num?)?.toDouble() ?? 0.0;

          return Card(
            margin: const EdgeInsets.symmetric(vertical: 4),
            color: cardColor, // ⭐️ Pure White for Card ⭐️
            child: ListTile(
              title: Text(
                description,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              subtitle: Text(
                category,
                style: const TextStyle(color: Colors.black54),
              ),
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

    // 🚨 FIX: Inner Scaffold body content must be placed inside a SingleChildScrollView
    return SingleChildScrollView(
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
              color: cardColor, // ⭐️ Pure White for Card ⭐️
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      'Current Balance',
                      style: Theme.of(
                        context,
                      ).textTheme.titleLarge?.copyWith(color: textColor),
                    ),
                    Text(
                      _formatCurrency(_currentBalance),
                      style: Theme.of(
                        context,
                      ).textTheme.displaySmall?.copyWith(color: textColor),
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
                      'Spent this month: ${_formatCurrency(_totalSpent)} / ${_formatCurrency(_monthlyBudget)}',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: textColor),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Budget Progress for top 3 categories
            Text(
              'Budget Progress (Top Categories)',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.white,
              ), // White text on gradient
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
                  backgroundColor:
                      Colors.white30, // Lighter background for progress bar
                  progressColor: progress > 1.0
                      ? Colors.red
                      : _primaryColor, // Deep Teal for progress
                  barRadius: const Radius.circular(8),
                  center: Text(
                    "$category: ${_formatCurrency(spent)} / ${_formatCurrency(budget)}",
                    style: const TextStyle(fontSize: 12, color: Colors.white),
                  ),
                ),
              );
            }),
            const SizedBox(height: 20),

            // Recent Transactions (Date-grouped)
            Text(
              'Recent Transactions (Last 7 Days)',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.white,
              ), // White text on gradient
            ),
            if (_groupedTransactions.isNotEmpty)
              ...datedTransactionList
            else
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Center(
                  child: Text(
                    'No transactions found in the last 7 days.',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white70,
                    ), // Lighter text on gradient
                  ),
                ),
              ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finsage/services/news_service.dart';
import 'package:finsage/services/insights_service.dart';
import 'package:url_launcher/url_launcher.dart';

// Updated color constants to match dashboard_page.dart
const Color _primaryColor = Color(0xFF008080); // Deep Teal
const Color _secondaryColor = Color(0xFFB76E79); // Rose Gold
const Color _gradientStartColor = Color(0xFF2C3E50); // Dark Blue-Purple
const Color _gradientEndColor = Color(0xFF4CA1AF); // Lighter Blue-Teal
const Color _cardColor = Color(0xFFFFFFFF); // Pure White

class InsightsPage extends StatefulWidget {
  const InsightsPage({super.key});

  @override
  State<InsightsPage> createState() => _InsightsPageState();
}

class _InsightsPageState extends State<InsightsPage> {
  bool _receiveSuggestions = false;
  bool _isLoading = true;

  final InsightsService _insightsService = InsightsService();

  @override
  void initState() {
    super.initState();
    _checkAndFetchData();
  }

  Future<void> _checkAndFetchData() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (mounted) {
          setState(() {
            _receiveSuggestions =
                userDoc.data()?['receiveSuggestions'] ?? false;
            _isLoading = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } else {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _launchUrl(String url) async {
    if (!await launchUrl(Uri.parse(url))) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not launch $url'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [_gradientStartColor, _gradientEndColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    if (!_receiveSuggestions) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            'Financial Insights',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: _primaryColor,
          elevation: 0,
          automaticallyImplyLeading: false,
        ),
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [_gradientStartColor, _gradientEndColor],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Financial suggestions are turned off. You can enable them in your profile settings.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Financial Insights',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: _primaryColor,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [_gradientStartColor, _gradientEndColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildNewsAndTipsCard(),
                const SizedBox(height: 20),
                _buildSpendingInsightsCard(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 📰 News & Tips (from NewsService)
  Widget _buildNewsAndTipsCard() {
    return FutureBuilder<List<Map<String, String>>>(
      future: NewsService().fetchFinancialNewsAndTips(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.white),
          );
        }
        if (snapshot.hasError) {
          return Card(
            color: _cardColor,
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Error: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
              ),
            ),
          );
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Card(
            color: _cardColor,
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'No news or tips available.',
                style: TextStyle(color: Colors.black),
              ),
            ),
          );
        }

        final content = snapshot.data!;

        return Card(
          color: _cardColor,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.lightbulb, color: _primaryColor, size: 24),
                    const SizedBox(width: 8),
                    const Text(
                      'Financial Insights',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
                Divider(color: Colors.grey.shade300, height: 20),
                ...content.map(
                  (item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: InkWell(
                      onTap: item['url'] != null && item['url']!.isNotEmpty
                          ? () => _launchUrl(item['url']!)
                          : null,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.star, size: 16, color: _secondaryColor),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              item['text']!,
                              style: TextStyle(
                                fontSize: 14,
                                decoration:
                                    (item['url'] != null &&
                                        item['url']!.isNotEmpty)
                                    ? TextDecoration.underline
                                    : TextDecoration.none,
                                color: Colors.black87,
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
        );
      },
    );
  }

  /// 💰 Spending Insights (from InsightsService)
  Widget _buildSpendingInsightsCard() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Card(
        color: _cardColor,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            "Please sign in to see your spending insights.",
            style: TextStyle(fontSize: 16, color: Colors.red),
          ),
        ),
      );
    }

    return FutureBuilder<Map<String, dynamic>>(
      future: _insightsService.analyzeSpending(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.white),
          );
        }
        if (snapshot.hasError) {
          return Card(
            color: _cardColor,
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Error: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
              ),
            ),
          );
        }
        if (!snapshot.hasData) {
          return Card(
            color: _cardColor,
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'No spending data available.',
                style: TextStyle(color: Colors.black),
              ),
            ),
          );
        }

        final data = snapshot.data!;
        final double totalThis = (data['totalThisMonth'] ?? 0.0).toDouble();
        final double totalLast = (data['totalLastMonth'] ?? 0.0).toDouble();
        final double percentChange = (data['percentChange'] ?? 0.0).toDouble();
        final Map<String, double> categoryTotals = Map<String, double>.from(
          data['categoryTotals'] ?? {},
        );
        final List<String> suggestions = List<String>.from(
          data['suggestions'] ?? [],
        );

        return Card(
          color: _cardColor,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.trending_up, color: _primaryColor, size: 24),
                    const SizedBox(width: 8),
                    const Text(
                      'Spending Insights',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
                Divider(color: Colors.grey.shade300, height: 20),
                Text(
                  "Total This Month: ₹${totalThis.toStringAsFixed(2)}",
                  style: const TextStyle(fontSize: 16, color: Colors.black),
                ),
                const SizedBox(height: 4),
                Text(
                  "Last Month: ₹${totalLast.toStringAsFixed(2)}",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  totalLast > 0
                      ? "Change: ${percentChange.toStringAsFixed(1)}%"
                      : (totalThis > 0
                            ? "New activity this month"
                            : "No activity"),
                  style: TextStyle(
                    fontSize: 14,
                    color: percentChange > 0 ? Colors.red : Colors.green,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),

                if (categoryTotals.isNotEmpty) ...[
                  const Text(
                    "Category breakdown:",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...categoryTotals.entries.map(
                    (e) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              e.key,
                              style: const TextStyle(color: Colors.black87),
                            ),
                          ),
                          Text(
                            "₹${e.value.toStringAsFixed(2)}",
                            style: TextStyle(
                              color: _primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                const Text(
                  "Suggestions:",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                ...suggestions.map(
                  (s) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.circle, size: 8, color: _secondaryColor),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            s,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

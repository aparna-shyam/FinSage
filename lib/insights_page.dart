import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finsage/services/news_service.dart';
import 'package:finsage/services/insights_service.dart'; // ✅ uses InsightsService
import 'package:url_launcher/url_launcher.dart';

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
        final userDoc =
            await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

        if (mounted) {
          setState(() {
            _receiveSuggestions = userDoc.data()?['receiveSuggestions'] ?? false;
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final cardColor = isDarkMode ? Colors.grey[850] : Colors.white;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!_receiveSuggestions) {
      return Scaffold(
        backgroundColor: const Color(0xFFECE2D2),
        appBar: AppBar(
          title: const Text('Financial Insights'),
          backgroundColor: const Color(0xFFD9641E),
          elevation: 0,
          automaticallyImplyLeading: false,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Financial suggestions are turned off. You can enable them in your profile settings.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, color: textColor),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFECE2D2),
      appBar: AppBar(
        title: const Text('Financial Insights'),
        backgroundColor: const Color(0xFFD9641E),
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildNewsAndTipsCard(textColor, cardColor),
              const SizedBox(height: 20),
              _buildSpendingInsightsCard(textColor, cardColor),
            ],
          ),
        ),
      ),
    );
  }

  /// 📰 News & Tips (from NewsService)
  Widget _buildNewsAndTipsCard(Color textColor, Color? cardColor) {
    final Color whiteCard = Colors.white;

    return FutureBuilder<List<Map<String, String>>>(
      future: NewsService().fetchFinancialNewsAndTips(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Text('No news or tips available.');
        }

        final content = snapshot.data!;

        return Container(
          decoration: BoxDecoration(
            color: whiteCard,
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
                      Icon(Icons.lightbulb, color: textColor, size: 24),
                      const SizedBox(width: 8),
                      Text(
                        'Financial Insights',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                  Divider(color: textColor, height: 20),
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
                            Icon(Icons.star, size: 16, color: textColor),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                item['text']!,
                                style: TextStyle(
                                  fontSize: 14,
                                  decoration: (item['url'] != null &&
                                          item['url']!.isNotEmpty)
                                      ? TextDecoration.underline
                                      : TextDecoration.none,
                                  color: textColor,
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
      },
    );
  }

  /// 💰 Spending Insights (from InsightsService)
  Widget _buildSpendingInsightsCard(Color textColor, Color? cardColor) {
    final Color whiteCard = Colors.white;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: whiteCard,
          borderRadius: BorderRadius.circular(15),
        ),
        child: const Text(
          "Please sign in to see your spending insights.",
          style: TextStyle(fontSize: 16, color: Colors.red),
        ),
      );
    }

    return FutureBuilder<Map<String, dynamic>>(
      future: _insightsService.analyzeSpending(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }
        if (!snapshot.hasData) {
          return const Text('No spending data available.');
        }

        final data = snapshot.data!;
        final double totalThis = (data['totalThisMonth'] ?? 0.0).toDouble();
        final double totalLast = (data['totalLastMonth'] ?? 0.0).toDouble();
        final double percentChange = (data['percentChange'] ?? 0.0).toDouble();
        final Map<String, double> categoryTotals =
            Map<String, double>.from(data['categoryTotals'] ?? {});
        final List<String> suggestions =
            List<String>.from(data['suggestions'] ?? []);

        return Container(
          decoration: BoxDecoration(
            color: whiteCard,
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
                      Icon(Icons.trending_up, color: textColor, size: 24),
                      const SizedBox(width: 8),
                      Text(
                        'Spending Insights',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                  Divider(color: textColor, height: 20),
                  Text("Total This Month: ₹${totalThis.toStringAsFixed(2)}",
                      style: TextStyle(fontSize: 16, color: textColor)),
                  const SizedBox(height: 4),
                  Text("Last Month: ₹${totalLast.toStringAsFixed(2)}",
                      style: TextStyle(fontSize: 14, color: textColor.withOpacity(0.8))),
                  const SizedBox(height: 6),
                  Text(
                    totalLast > 0
                        ? "Change: ${percentChange.toStringAsFixed(1)}%"
                        : (totalThis > 0
                            ? "New activity this month"
                            : "No activity"),
                    style: TextStyle(fontSize: 14, color: textColor),
                  ),
                  const SizedBox(height: 12),

                  if (categoryTotals.isNotEmpty) ...[
                    Text("Category breakdown:",
                        style: TextStyle(fontSize: 16, color: textColor)),
                    const SizedBox(height: 8),
                    ...categoryTotals.entries.map((e) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(e.key,
                                    style: TextStyle(color: textColor)),
                              ),
                              Text("₹${e.value.toStringAsFixed(2)}",
                                  style: TextStyle(color: textColor)),
                            ],
                          ),
                        )),
                    const SizedBox(height: 12),
                  ],

                  Text("Suggestions:",
                      style: TextStyle(fontSize: 16, color: textColor)),
                  const SizedBox(height: 6),
                  ...suggestions.map(
                    (s) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.circle, size: 8, color: textColor),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(s,
                                style: TextStyle(fontSize: 14, color: textColor)),
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
      },
    );
  }
}

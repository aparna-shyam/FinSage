import 'package:flutter/material.dart';
import 'package:finsage/services/news_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

class InsightsPage extends StatefulWidget {
  const InsightsPage({super.key});

  @override
  State<InsightsPage> createState() => _InsightsPageState();
}

class _InsightsPageState extends State<InsightsPage> {
  List<Map<String, String>> _financialNewsAndTips = [];
  List<String> _investmentSuggestions = [];
  bool _receiveSuggestions = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkAndFetchData();
  }

  Future<void> _checkAndFetchData() async {
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
            _isLoading = false;
          });
          if (_receiveSuggestions) {
            _fetchFinancialNewsAndTips();
            _fetchInvestmentSuggestions();
          }
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
    final cardColor = isDarkMode ? Colors.grey[850] : null;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!_receiveSuggestions) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Financial suggestions are turned off. You can enable them in your profile settings.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, color: textColor),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Financial Insights'),
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
              _buildNewsAndTipsCard(textColor, cardColor),
              const SizedBox(height: 20),
              _buildInvestmentSuggestionsCard(textColor, cardColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNewsAndTipsCard(Color textColor, Color? cardColor) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor, // Use a single color for dark mode
        gradient: cardColor == null
            ? LinearGradient(
                colors: [Colors.green.shade100, Colors.lightGreen.shade50],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
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
                        Icon(Icons.star, size: 16, color: textColor),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            item['text']!,
                            style: TextStyle(
                              fontSize: 14,
                              decoration: item['url']!.isNotEmpty
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
  }

  Widget _buildInvestmentSuggestionsCard(Color textColor, Color? cardColor) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor, // Use a single color for dark mode
        gradient: cardColor == null
            ? LinearGradient(
                colors: [Colors.blue.shade100, Colors.blue.shade50],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
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
              Row(
                children: [
                  Icon(Icons.trending_up, color: textColor, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    'Investment Suggestions',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ],
              ),
              Divider(color: textColor, height: 20),
              ..._investmentSuggestions.map(
                (item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.arrow_right, size: 16, color: textColor),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item,
                          style: TextStyle(fontSize: 14, color: textColor),
                        ),
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
}

// lib/services/news_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class NewsService {
  final String _finnhubApiToken = dotenv.env['FINNHUB_API_TOKEN']!;

  final List<String> _financialTips = [
    "Start with a budget to track your income and expenses.",
    "Pay off high-interest debt first to save money in the long run.",
    "Automate your savings by setting up regular transfers to a separate account.",
    "Invest in a diversified portfolio to minimize risk.",
    "Build an emergency fund to cover 3-6 months of living expenses.",
    "Review your subscriptions and cancel any you don't use regularly.",
    "Create a 'wants' list and wait before making impulse purchases.",
  ];

  Future<List<Map<String, String>>> fetchFinancialNewsAndTips() async {
    final List<Map<String, String>> content = [];
    final String apiUrl =
        "https://finnhub.io/api/v1/news?category=general&token=$_finnhubApiToken";

    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final headlines = data
            .take(3)
            .map(
              (article) => {
                'text': article['headline'] as String,
                'url': article['url'] as String,
              },
            )
            .toList();
        content.addAll(headlines);
      }
    } catch (e) {
      content.add({'text': "Error fetching news: $e", 'url': ''});
    }

    // 🔹 Instead of 1 random tip, pick 3 random unique tips
    final tips = (List.of(_financialTips)..shuffle()).take(3).toList();
    for (var tip in tips) {
      content.add({'text': 'Tip: $tip', 'url': ''});
    }

    return content;
  }

  Future<List<String>> fetchInvestmentSuggestions() async {
    final List<String> suggestions = [];
    final String apiUrl =
        "https://finnhub.io/api/v1/stock/symbol?exchange=US&token=$_finnhubApiToken";

    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final List<dynamic> allStocks = json.decode(response.body);

        final randomStocks = (List.of(allStocks)..shuffle()).take(3).toList();

        for (var stock in randomStocks) {
          final symbol = stock['symbol'] as String;
          suggestions.add(
            "Consider investing in $symbol. Recent trends show positive momentum.",
          );
        }
      }
    } catch (e) {
      suggestions.add("Could not fetch investment suggestions: $e");
    }

    return suggestions;
  }
}

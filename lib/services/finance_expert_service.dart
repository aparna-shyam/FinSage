import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FinanceExpertService {
  final String _apiUrl = "https://api.groq.com/openai/v1/chat/completions";

  Future<String> askExpert(String userMessage) async {
    final apiKey = dotenv.env['GROQ_API_KEY']?.trim() ?? "";

    try {
      final user = FirebaseAuth.instance.currentUser;
      final snapshot = await FirebaseFirestore.instance
          .collection('spending')
          .where('userId', isEqualTo: user?.uid)
          .orderBy('date', descending: true)
          .limit(5)
          .get();

      String contextData = "";
      for (var doc in snapshot.docs) {
        contextData += "${doc['description']} (₹${doc['amount']}), ";
      }

      final body = {
        "model": "llama-3.3-70b-versatile", // Powerful & fast
        "messages": [
          {
            "role": "system",
            "content":
                "You are Bodhi, a finance expert. User data: $contextData. Keep advice brief.",
          },
          {"role": "user", "content": userMessage},
        ],
        "temperature": 0.7,
      };

      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $apiKey",
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'];
      } else {
        print(
          "DEBUG: Groq Failed with ${response.statusCode} - ${response.body}",
        );
        return "Bodhi is resetting. Try again in a second.";
      }
    } catch (e) {
      return "Connection error. Please check your internet.";
    }
  }
}

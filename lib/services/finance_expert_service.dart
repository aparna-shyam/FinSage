import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FinanceExpertService {
  late final GenerativeModel _model;
  late final ChatSession _chat;

  FinanceExpertService() {
    final apiKey = dotenv.env['GEMINI_API_KEY'] ?? "";

    _model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: apiKey,
      systemInstruction: Content.system(
        "You are FinSage AI, a certified financial advisor. "
        "Use the provided transaction data to give specific advice. "
        "If a user is overspending in a category, point it out. "
        "Always be encouraging but professional. Use Markdown for formatting.",
      ),
    );
    _chat = _model.startChat();
  }

  Future<String> askExpert(String userMessage) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final snapshot = await FirebaseFirestore.instance
          .collection('spending')
          .where('userId', isEqualTo: user?.uid)
          .orderBy('date', descending: true)
          .limit(5)
          .get();

      String context = "Recent Transactions:\n";
      for (var doc in snapshot.docs) {
        context +=
            "- ${doc['description']}: ₹${doc['amount']} (${doc['category']})\n";
      }

      final fullPrompt = "Context:\n$context\n\nUser Question: $userMessage";
      final response = await _chat.sendMessage(Content.text(fullPrompt));
      return response.text ?? "I'm not sure how to answer that right now.";
    } catch (e) {
      return "Expert Error: ${e.toString()}";
    }
  }
}

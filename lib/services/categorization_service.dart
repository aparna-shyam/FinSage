import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart'; // Import dotenv

// Get the API token from the .env file
final String _huggingFaceApiToken = dotenv.env['HUGGING_FACE_TOKEN']!;

// The model you've chosen from Hugging Face for zero-shot classification.
const String _modelName = "facebook/bart-large-mnli";

Future<String> categorizeExpense(String expenseDescription) async {
  // The API URL for the Hugging Face Inference API
  final String apiUrl =
      "https://api-inference.huggingface.co/models/$_modelName";

  final List<String> candidateLabels = [
    "Food & Drink",
    "Shopping",
    "Transport",
    "Bills",
    "Groceries",
    "Entertainment",
    "Health",
    "Education",
    "Other",
  ];

  final Map<String, dynamic> requestBody = {
    "inputs": expenseDescription,
    "parameters": {"candidate_labels": candidateLabels, "multi_label": false},
  };

  try {
    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $_huggingFaceApiToken",
      },
      body: json.encode(requestBody),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      final List<dynamic> labels = data['labels'];
      final List<dynamic> scores = data['scores'];

      String bestCategory = "Other";
      double highestScore = 0.0;

      for (int i = 0; i < scores.length; i++) {
        if (scores[i] > highestScore) {
          highestScore = scores[i];
          bestCategory = labels[i];
        }
      }

      return bestCategory;
    } else {
      debugPrint("API Error: ${response.statusCode}, ${response.body}");
      return "Other";
    }
  } catch (e) {
    debugPrint("Network Error: $e");
    return "Other";
  }
}

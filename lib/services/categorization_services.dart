// lib/services/categorization_service.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

const String _apiUrl = "http://10.111.66.250:5000/categorize_expense";

Future<String> categorizeExpense(String expenseDescription) async {
  final Map<String, dynamic> requestBody = {"description": expenseDescription};

  try {
    final response = await http.post(
      Uri.parse(_apiUrl),
      headers: {"Content-Type": "application/json"},
      body: json.encode(requestBody),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['category'] as String;
    } else {
      debugPrint("API Error: ${response.statusCode}, ${response.body}");
      return "Other";
    }
  } catch (e) {
    debugPrint("Network Error: $e");
    return "Other";
  }
}

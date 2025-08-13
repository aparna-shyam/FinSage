import 'package:flutter/material.dart';
import 'signup_page.dart';

class IntroPage extends StatelessWidget {
  const IntroPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F4F9), // same soft pastel background
      appBar: AppBar(
        backgroundColor: const Color(0xFF6B5B95), // pastel purple
        title: const Text(
          "About FinSage",
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Title
              Text(
                "FinSage",
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF6B5B95), // pastel purple
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),

              // Subtitle
              Text(
                "Intelligent Financial Management Application",
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey[700],
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 25),

              // Intro paragraph
              Text(
                "FinSage is a financial management app that helps users track expenses, "
                "categorize them automatically using AI, and predict future budgets. "
                "Built with a secure backend, intuitive UI, and scalable architecture "
                "for seamless performance.\n\n"
                "It combines an intuitive Frontend UI with a robust Backend API, "
                "a secure Database, and AI-powered models for automated expense "
                "categorization and future budget predictions.\n\n"
                "The system ensures smooth data flow between the user interface, backend logic, "
                "database, and AI models, providing users with accurate insights and a seamless "
                "financial tracking experience.",
                style: const TextStyle(fontSize: 16, height: 1.5),
                textAlign: TextAlign.justify,
              ),
              const SizedBox(height: 25),

              // Key Features
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFB5EAD7), // pastel green
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      "Key Features:",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 10),
                    FeatureItem(
                      "User-friendly interface for expense tracking and budget management.",
                    ),
                    FeatureItem("AI-driven expense categorization."),
                    FeatureItem("Predictive analytics for future budgeting."),
                    FeatureItem("Secure and reliable data storage."),
                    FeatureItem(
                      "Scalable architecture for future feature enhancements.",
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // Proceed Button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFBC4AB), // pastel coral
                  foregroundColor: Colors.black87,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 50,
                    vertical: 15,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SignUpPage()),
                  );
                },
                child: const Text("Proceed", style: TextStyle(fontSize: 18)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FeatureItem extends StatelessWidget {
  final String text;
  const FeatureItem(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "• ",
            style: TextStyle(fontSize: 18, color: Colors.black87),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 16, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'login_page.dart';
import 'signup_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F4F9), // soft pastel background
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App Name
                Text(
                  'FinSage',
                  style: TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF6B5B95), // pastel purple
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Your Smart Finance Companion',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 50),

                // Log In Button
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFB5EAD7), // pastel green
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
                      MaterialPageRoute(builder: (context) => LoginPage()),
                    );
                  },
                  child: const Text('Log In', style: TextStyle(fontSize: 18)),
                ),

                const SizedBox(height: 20),

                // Sign Up Button
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFFBC4AB), // pastel coral
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
                      MaterialPageRoute(builder: (context) => SignUpPage()),
                    );
                  },
                  child: const Text('Sign Up', style: TextStyle(fontSize: 18)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

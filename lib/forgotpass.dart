import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Theme Colors from DashboardPage
// 💠 Define the Primary/Accent color: Deep Teal ⭐️
const Color _primaryColor = Color(0xFF008080);

// 🔵 Gradient Start Color: Dark Blue-Purple
const Color _gradientStartColor = Color(0xFF2C3E50);
// 🔷 Gradient End Color: Lighter Blue-Teal
const Color _gradientEndColor = Color(0xFF4CA1AF);

class ForgotPassPage extends StatefulWidget {
  const ForgotPassPage({super.key});

  @override
  _ForgotPassPageState createState() => _ForgotPassPageState();
}

class _ForgotPassPageState extends State<ForgotPassPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  // Function to send the password reset email
  Future<void> _sendPasswordResetEmail() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return; // Stop if validation fails
    }

    // ignore: use_build_context_synchronously
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Sending password reset email...'),
        duration: Duration(seconds: 1),
      ),
    );

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: _emailController.text.trim(),
      );

      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'A password reset link has been sent to your email. Please check your inbox.',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } on FirebaseAuthException catch (e) {
      String message;
      if (e.code == 'user-not-found') {
        message = 'No user found for that email.';
      } else if (e.code == 'invalid-email') {
        message = 'The email address is not valid.';
      } else {
        message = 'An unexpected error occurred: ${e.message}';
      }
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar uses the Deep Teal primary color
      appBar: AppBar(
        backgroundColor: _primaryColor,
        title: const Text(
          'Forgot Password',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      // Apply the gradient background to the body
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [_gradientStartColor, _gradientEndColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Center(
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // --- Lock Icon ---
                    const Icon(Icons.lock_reset, size: 80, color: Colors.white),
                    const SizedBox(height: 30),

                    // --- Instruction Text ---
                    const Text(
                      'Enter your email to receive a password reset link:',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white70, // Light text for dark background
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 30),

                    // --- Email Field ---
                    _buildTextField(
                      controller: _emailController,
                      label: 'Email Address',
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 40),

                    // --- Submit Button ---
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryColor, // Deep Teal button
                        padding: const EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 40,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      onPressed: _sendPasswordResetEmail,
                      child: const Text(
                        'Send Reset Link',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Helper method for consistent text field styling
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.black87),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your email address.';
        }
        // Simple email regex for validation
        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
          return 'Please enter a valid email address.';
        }
        return null;
      },
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.black54),
        filled: true,
        fillColor: Colors.white, // White fill for text field on dark background
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 15,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        errorStyle: const TextStyle(
          color: Colors.yellowAccent,
          fontWeight: FontWeight.bold,
        ), // Visible error text
      ),
    );
  }
}

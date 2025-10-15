import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'main_app_page.dart';

// 💠 Define the Primary/Accent color: Deep Teal ⭐️
const Color _primaryColor = Color(0xFF008080);

// 🔵 Gradient Start Color: Dark Blue-Purple
const Color _gradientStartColor = Color(0xFF2C3E50);
// 🔷 Gradient End Color: Lighter Blue-Teal
const Color _gradientEndColor = Color(0xFF4CA1AF);

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  _ChangePasswordPageState createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    if (_formKey.currentState!.validate()) {
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await user.updatePassword(_passwordController.text);
          // ignore: use_build_context_synchronously
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Password updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          // ignore: use_build_context_synchronously
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MainAppPage()),
          );
        }
      } on FirebaseAuthException catch (e) {
        String message;
        if (e.code == 'weak-password') {
          message = 'The password is too weak.';
        } else {
          message = 'An error occurred: ${e.message}';
        }
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // The AppBar uses the primary color (Deep Teal)
      appBar: AppBar(
        title: const Text(
          'Change Password',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: _primaryColor,
        iconTheme: const IconThemeData(
          color: Colors.white,
        ), // Set back button color
      ),
      // Apply the gradient background to the body by wrapping the content
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [_gradientStartColor, _gradientEndColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Center(
              // Center the content vertically and horizontally
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Add lock icon above the text
                    const Icon(
                      Icons.lock_open_rounded,
                      size: 60,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'You have successfully signed in via email. Please set a new password:',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white70, // Light text for dark background
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 30),
                    _buildTextField(
                      controller: _passwordController,
                      label: 'New Password',
                      obscureText: true,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _confirmPasswordController,
                      label: 'Confirm New Password',
                      obscureText: true,
                    ),
                    const SizedBox(height: 40),
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
                      onPressed: _changePassword,
                      child: const Text(
                        'Update Password',
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    bool obscureText = false,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      style: const TextStyle(
        color: Colors.black87,
      ), // Ensure input text is visible
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter $label';
        }
        if (label == 'Confirm New Password' &&
            value != _passwordController.text) {
          return 'Passwords do not match';
        }
        return null;
      },
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          color: Colors.black54,
        ), // Label in white field
        filled: true,
        fillColor: Colors.white, // White fill for text field
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
        ), // Error on dark background
      ),
    );
  }
}
